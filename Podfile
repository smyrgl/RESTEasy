workspace 'RESTEasy'
xcodeproj 'Tests/Tests.xcodeproj'
xcodeproj 'Example/RESTEasyApp/RESTEasyApp.xcodeproj'

inhibit_all_warnings!

target :iostests do
  platform :ios, '7.0'
  pod 'GCDWebServer', :git => 'https://github.com/swisspol/GCDWebServer.git'
  pod 'Gizou'
  pod 'FMDB'
  pod 'InflectorKit'
  pod 'AFNetworking'
  pod 'XCAsyncTestCase'
  xcodeproj 'Tests/Tests.xcodeproj'
end

target :osxtests do
  platform :osx, '10.9'
  pod 'GCDWebServer', :git => 'https://github.com/swisspol/GCDWebServer.git'
  pod 'Gizou'
  pod 'FMDB'
  pod 'InflectorKit'
  pod 'AFNetworking'
  pod 'XCAsyncTestCase'
  xcodeproj 'Tests/Tests.xcodeproj'
end

target :RESTEasyApp do 
  platform :ios, '7.0'
  pod 'GCDWebServer', :git => 'https://github.com/swisspol/GCDWebServer.git'
  pod 'Gizou'
  pod 'FMDB'
  pod 'InflectorKit'
  pod 'AFNetworking'
  xcodeproj 'Example/RESTEasyApp/RESTEasyApp.xcodeproj'
end

target :sandbox do
  platform :osx, '10.9'
  pod 'GCDWebServer', :git => 'https://github.com/swisspol/GCDWebServer.git'
  pod 'FMDB'
  pod 'InflectorKit'
  xcodeproj 'Tests/Tests.xcodeproj'
end

