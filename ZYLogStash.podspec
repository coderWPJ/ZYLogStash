Pod::Spec.new do |s|
  s.name = "ZYLogStash"
  s.version = "0.0.12"
  s.summary = "ZYLogStash"
  s.homepage = "https://github.com/coderWPJ"
  s.license= "MIT"
  s.author = {
    "WPJ" => "331321408@qq.com",
  }
  s.source = { :git => "https://github.com/coderWPJ/ZYLogStash.git", :tag => s.version }
  s.source_files = "ZYLogStash/*.{h,m}"
  s.requires_arc = true


  s.ios.deployment_target = "8.0"

end
