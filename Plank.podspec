Pod::Spec.new do |s|
  s.name = 'Plank'
  s.version = '1.0.5'
  s.license = 'Apache 2.0'
  s.summary = 'Swift Logger'
  s.homepage = 'https://github.com/banDedo/Plank'
  s.authors = { 'Patrick Hogan' => 'phoganuci@gmail.com' }
  s.source = { :git => 'https://github.com/banDedo/Plank.git', :tag => s.version }

  s.ios.deployment_target = '7.0'

  s.source_files = 'Plank/Plank/BDSystemLogger.{h,m}', 'Plank/Plank/Logger.swift'

  s.requires_arc = true
end