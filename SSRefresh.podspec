#
# Be sure to run `pod lib lint SwiftyRefresh.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SSRefresh'
  s.version          = '0.1.2'
  s.summary          = 'SSRefresh. inspired by MJRefresh, overwrited by Swift'
  s.homepage         = 'https://github.com/ws00801526/SSRefresh'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Fraker.XM' => '3057600441@qq.com' }
  s.source           = { :git => 'https://github.com/ws00801526/SSRefresh.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.default_subspec = 'SR'

  s.subspec 'Base' do |ss|
    ss.resource = 'Sources/SSRefresh/*.{lproj,png}'
    ss.source_files = 'Sources/SSRefresh/*.swift'
  end

  s.subspec 'MJ' do |ss|
    ss.dependency 'SSRefresh/Base'
    ss.source_files = 'Sources/SSRefresh/MJ/**/*'
  end

  s.subspec 'SR' do |ss|
    ss.dependency 'SSRefresh/Base'
    ss.source_files = 'Sources/SSRefresh/SR/SSRefresh.swift', 'Sources/SSRefresh/SR/SSRefresh+RefreshView.swift'
    ss.subspec 'Rx' do |sss|
      sss.dependency 'RxSwift'
      sss.dependency 'RxCocoa'
      sss.source_files = 'Sources/SSRefresh/SR/SSRefresh+Reactive.swift'
    end
  end

end
