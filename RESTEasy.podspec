Pod::Spec.new do |s|
  s.name             = "RESTEasy"
  s.version          = "0.1.0"
  s.summary          = "A dead simple RESTful server that runs INSIDE your iOS/OSX app."
  s.homepage         = "https://github.com/smyrgl/RESTEasy"
  s.license          = 'MIT'
  s.author           = { "John Tumminaro" => "john@tinylittlegears.com" }
  s.source           = { :git => "https://github.com/smyrgl/RESTEasy.git", :tag => s.version.to_s }

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.requires_arc = true

  s.source_files = 'Classes'
  s.exclude_files = 'Classes/Private'
  s.resources = 'Assets/*.png'

  s.public_header_files = 'Classes/*.h'
  s.frameworks = 'Foundation'
  s.dependency 'GCDWebServer', '~> 2.3.2'
  s.dependency 'Gizou', '~> 0.1.3'
  s.dependency 'FMDB', '~> v2.1'
end
