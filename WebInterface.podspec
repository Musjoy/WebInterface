#
# Be sure to run `pod lib lint WebInterface.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WebInterface'
  s.version          = '0.1.0'
  s.summary          = 'This is a generic web interface.'

  s.homepage         = 'https://github.com/Musjoy/WebInterface'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Raymond' => 'Ray.musjoy@gmail.com' }
  s.source           = { :git => 'https://github.com/Musjoy/WebInterface.git', :tag => "v-#{s.version}" }

  s.ios.deployment_target = '7.0'

  s.default_subspec = 'Core'

  s.user_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => 'MODULE_WEB_INTERFACE'
  }

  s.subspec 'Core' do |ss|
    ss.source_files = 'WebInterface/Classes/*.{h,m}'
  end
  
  s.subspec 'ListRequest' do |ss|
    ss.source_files = 'WebInterface/Classes/ListRequest/*.{h,m}'
    ss.user_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => 'MODULE_WEB_INTERFACE_LIST_REQUEST'
    }
    pch_AF = <<-EOS
#import "ModuleCapability.h"
#ifndef MODULE_WEB_INTERFACE_LIST_REQUEST
#define MODULE_WEB_INTERFACE_LIST_REQUEST
#endif
    EOS
    ss.prefix_header_contents = pch_AF

  end

  s.dependency 'MJWebService', '~> 0.1.1'
  s.dependency 'ActionProtocol', '~> 0.1.0'
  s.dependency 'DBModel', '~> 0.1.2'
  s.dependency 'ModuleCapability', '~> 0.1.2'
  s.prefix_header_contents = '#import "ModuleCapability.h"'

end
