Pod::Spec.new do |s|
  s.name             = 'Binson'
  s.version          = '2.0.1'
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
  s.screenshots      = 'http://binson.org/logo.png'

  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { 'kpernyer'  => 'kenneth.pernyer@assaabloy.com',
                'TheHawkis' => 'hakan.ohlsson@assaabloy.com',
                'Dreadrik' => 'dreadrik@gmail.com' }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.13'

  s.source = { :git => 'https://github.com/assaabloy-ppi/binson-swift.git', :tag => s.version.to_s }
  s.source_files = 'Sources/*.{swift}'
  s.public_header_files = "Sources/Binson.h"

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
end
