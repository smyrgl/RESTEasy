workspace 'RESTEasy'
xcodeproj 'Tests/Tests.xcodeproj'

inhibit_all_warnings!

target :iostests do
  platform :ios, '7.0'
  pod 'GCDWebServer'
  pod 'Gizou'
  pod 'FMDB'
	xcodeproj 'Tests/Tests.xcodeproj'
end

target :osxtests do
	platform :osx, '10.9'
	pod 'GCDWebServer'
  pod 'Gizou'
  pod 'FMDB'
	xcodeproj 'Tests/Tests.xcodeproj'
end
