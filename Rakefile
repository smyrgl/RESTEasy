namespace :test do 
  task :prepare do 
    mkdir_p "Tests/Tests.xcodeproj/xcshareddata/xcschemes"
    cp Dir.glob('Tests/Schemes/*.xcscheme'), "Tests/Tests.xcodeproj/xcshareddata/xcschemes/"
  end
  
  desc "Run the RESTEasy Tests for iOS"
  task :ios => :prepare do
    run_tests('iostests', 'iphonesimulator')
    tests_failed('iOS') unless $?.success?
  end

  desc "Run the RESTEasy Tests for Mac OSX"
  task :osx => :prepare do
    run_tests('osxtests', 'macosx')
    tests_failed('OSX') unless $?.success?
  end
end

namespace :appledoc do 
  task :check do 
    unless File.exists?('/usr/local/bin/appledoc')
      puts "appledoc not found at /usr/local/bin/appledoc: Install via homebrew and try again: `brew install --HEAD appledoc`"
      exit 1
    end
  end
end

desc "Runs the RESTEasy specs"
task :spec do
  Rake::Task['test:ios'].invoke
  Rake::Task['test:osx'].invoke if is_mavericks_or_above
end

namespace :docs do 
  desc "Generates the RESTEasy documentation using Appledoc"
  task :generate => 'appledoc:check' do
    command = apple_doc_command << " --no-create-docset --keep-intermediate-files --create-html `find Classes/ -name '*.h'`"
    run(command, 1)
    puts "Generated documentationa at Docs/html"
  end

  desc "Check that documentation can be built from the source code via appledoc successfully."
  task :check => 'appledoc:check' do
    command = apple_doc_command << " --no-create-html --verbose 5 `find Classes/ -name '*.h'`"
    exitstatus = run(command, 1)
    if exitstatus == 0
      puts "appledoc generation completed successfully!"
    elsif exitstatus == 1
      puts "appledoc generation produced warnings"
    elsif exitstatus == 2
      puts "! appledoc generation encountered an error"
      exit(exitstatus)
    else
      puts "!! appledoc generation failed with a fatal error"
    end    
    exit(exitstatus)
  end
end

task :version do
  git_remotes = `git remote`.strip.split("\n")

  if git_remotes.count > 0
    puts "-- fetching version number from github"
    sh 'git fetch'

    remote_version = remote_spec_version
  end

  if remote_version.nil?
    puts "There is no current released version. You're about to release a new Pod."
    version = "0.0.1"
  else
    puts "The current released version of your pod is " +
          remote_spec_version.to_s()
    version = suggested_version_number
  end
  
  puts "Enter the version you want to release (" + version + ") "
  new_version_number = $stdin.gets.strip
  if new_version_number == ""
    new_version_number = version
  end

  replace_version_number(new_version_number)
end

desc "Release a new version of the Pod (append repo=name to push to a private spec repo)"
task :release do
  # Allow override of spec repo name using `repo=private` after task name
  repo = ENV["repo"] || "master"

  puts "* Running version"
  sh "rake version"

  unless ENV['SKIP_CHECKS']
    if `git symbolic-ref HEAD 2>/dev/null`.strip.split('/').last != 'master'
      $stderr.puts "[!] You need to be on the `master' branch in order to be able to do a release."
      exit 1
    end

    if `git tag`.strip.split("\n").include?(spec_version)
      $stderr.puts "[!] A tag for version `#{spec_version}' already exists. Change the version in the podspec"
      exit 1
    end

    puts "You are about to release `#{spec_version}`, is that correct? [y/n]"
    exit if $stdin.gets.strip.downcase != 'y'
  end

  puts "* Running specs"
  sh "rake spec"
 
  puts "* Linting the podspec"
  sh "pod lib lint"

  # Then release
  sh "git commit #{podspec_path} CHANGELOG.md -m 'Release #{spec_version}' --allow-empty"
  sh "git tag -a #{spec_version} -m 'Release #{spec_version}'"
  sh "git push origin master"
  sh "git push origin --tags"
  sh "pod push #{repo} #{podspec_path}"
end

# @return [Pod::Version] The version as reported by the Podspec.
#
def spec_version
  require 'cocoapods'
  spec = Pod::Specification.from_file(podspec_path)
  spec.version
end

# @return [Pod::Version] The version as reported by the Podspec from remote.
#
def remote_spec_version
  require 'cocoapods-core'

  if spec_file_exist_on_remote?
    remote_spec = eval(`git show origin/master:#{podspec_path}`)
    remote_spec.version
  else
    nil
  end
end

# @return [Bool] If the remote repository has a copy of the podpesc file or not.
#
def spec_file_exist_on_remote?
  test_condition = `if git rev-parse --verify --quiet origin/master:#{podspec_path} >/dev/null;
  then
  echo 'true'
  else
  echo 'false'
  fi`

  'true' == test_condition.strip
end

# @return [String] The relative path of the Podspec.
#
def podspec_path
  podspecs = Dir.glob('*.podspec')
  if podspecs.count == 1
    podspecs.first
  else
    raise "Could not select a podspec"
  end
end

# @return [String] The suggested version number based on the local and remote
#                  version numbers.
#
def suggested_version_number
  if spec_version != remote_spec_version
    spec_version.to_s()
  else
    next_version(spec_version).to_s()
  end
end

# @param  [Pod::Version] version
#         the version for which you need the next version
#
# @note   It is computed by bumping the last component of
#         the version string by 1.
#
# @return [Pod::Version] The version that comes next after
#                        the version supplied.
#
def next_version(version)
  version_components = version.to_s().split(".");
  last = (version_components.last.to_i() + 1).to_s
  version_components[-1] = last
  Pod::Version.new(version_components.join("."))
end

# @param  [String] new_version_number
#         the new version number
#
# @note   This methods replaces the version number in the podspec file
#         with a new version number.
#
# @return void
#
def replace_version_number(new_version_number)
  text = File.read(podspec_path)
  text.gsub!(/(s.version( )*= ")#{spec_version}(")/,
              "\\1#{new_version_number}\\3")
  File.open(podspec_path, "w") { |file| file.puts text }
end

private

def apple_doc_command
  "/usr/local/bin/appledoc -o Docs/ -p RESTEasy -v #{spec_version} -c \"RESTEasy\" " +
  "--company-id com.tinylittlegears --warn-undocumented-object --warn-undocumented-member  --warn-empty-description  --warn-unknown-directive " +
  "--warn-invalid-crossref --warn-missing-arg --no-repeat-first-par "
end

def run_tests(scheme, sdk)
  #sh("xcodebuild -workspace RESTEasy.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' -configuration Release clean test | xcpretty -c ; exit ${PIPESTATUS[0]}") rescue nil
  sh("xctool -workspace RESTEasy.xcworkspace -scheme '#{scheme}' -sdk '#{sdk}' -configuration Release clean test") rescue nil
end

def is_mavericks_or_above
  osx_version = `sw_vers -productVersion`.chomp
  Gem::Version.new(osx_version) >= Gem::Version.new('10.9')
end

def tests_failed(platform)
  puts red("#{platform} unit tests failed")
  exit $?.exitstatus
end

def red(string)
 "\033[0;31m! #{string}"
end

def run(command, min_exit_status = 0)
  puts "Executing: `#{command}`"
  system(command)
  if $?.exitstatus > min_exit_status
    puts "[!] Failed with exit code #{$?.exitstatus} while running: `#{command}`"
    exit($?.exitstatus)
  end
  return $?.exitstatus
end

