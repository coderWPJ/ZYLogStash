Pod::Spec.new do |s|
  s.name = "ZYLogStash"
  s.version = "2"
  s.summary = "ZYLogStash"
  s.homepage = "https://github.com/coderWPJ"
  s.license= "MIT"
  s.author = {
    "WPJ" => "331321408@qq.com",
  }
  s.source = { :git => "https://github.com/coderWPJ/ZYLogStash.git", :tag => s.version }
  s.source_files = "ZYLogStash/*.{h,m}"
  s.requires_arc = true
#s.private_header_files = "ZYLogStash/ZYLogStash.h"


  s.ios.deployment_target = "8.0"
  s.framework = "CFNetwork"

end
