workspace 'RESTEasy'
xcodeproj 'Tests/Tests.xcodeproj'
xcodeproj 'Example/RESTEasyApp/RESTEasyApp.xcodeproj'

inhibit_all_warnings!

def core_pods
  pod 'GCDWebServer', '~> 2.4'
  pod 'FMDB/standalone'
  pod 'InflectorKit'
end

def test_pods
  pod 'AFNetworking'
  pod 'Gizou'
  pod 'XCAsyncTestCase'
end

target :iostests do
  platform :ios, '7.0'
  core_pods
  test_pods
  xcodeproj 'Tests/Tests.xcodeproj'
end

target :osxtests do
  platform :osx, '10.9'
  core_pods
  test_pods
  xcodeproj 'Tests/Tests.xcodeproj'
end

target :RESTEasyApp do 
  platform :ios, '7.0'
  core_pods
  pod 'Foundry'
  pod 'SVProgressHUD'
  pod 'AFNetworking'
  xcodeproj 'Example/RESTEasyApp/RESTEasyApp.xcodeproj'
end

target :sandbox do
  platform :osx, '10.9'
  core_pods
  xcodeproj 'Tests/Tests.xcodeproj'
end

