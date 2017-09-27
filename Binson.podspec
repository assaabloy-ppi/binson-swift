Pod::Spec.new do |s|
  s.name             = 'Binson'
  s.version          = '1.0.2'
  s.summary          = 'Binson is a binary format for efficient IoT cases.'

  s.description      = <<-DESC
  Binson is an exceptionally simple binary data serialization format.
  It is similar in scope to JSON, but is faster, more compact, and simpler.

  Binson has full support for double precision floating point numbers
  (including NaN, inf). There is a one-to-one mapping between a Binson
  object and its serialized bytes. This is useful for cryptographic signatures,
  hash codes and equals operations. And the best feature: Binson has no nulls :-)
  DESC

  s.homepage         = 'http://binson.org'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kpernyer' => 'kenneth.pernyer@assaabloy.com' }
  s.source           = { :git => 'https://github.com/assaabloy-ppi/binson-swift.git', :tag => "1.0.2"}

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Binson/*.{swift}'
end
