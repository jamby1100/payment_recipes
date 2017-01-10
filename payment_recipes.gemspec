# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'payment_recipes/version'

included_files = [
  'version',
  'utils/action',
  'utils/converters',
  'utils/equality',
  'paypal/settings',
  'paypal/authorization',
  'paypal/capture',
  'paypal/payer',
  'paypal/payment',
  'paypal/refund',
  'paypal/sale',
  'paypal/transaction',
  'paypal/action/capture_authorization',
  'paypal/action/create_payment',
  'paypal/action/execute_payment',
  'paypal/action/refund_capture',
  'paypal/action/refund_sale',
  'paypal/action/void_authorization',
].map { |filename| "lib/payment_recipes/#{ filename }.rb" }

included_files << 'lib/payment_recipes.rb'

Gem::Specification.new do |spec|
  spec.name          = 'payment_recipes'
  spec.version       = PaymentRecipes::VERSION
  spec.authors       = ['Joshua Arvin Lat']
  spec.email         = ['joshua.arvin.lat@gmail.com']
  spec.summary       = %q{Wrapper classes and utilities to speed up payment gateway integration}
  spec.description   = %q{Wrapper classes and utilities to speed up payment gateway integration}
  spec.homepage      = ''
  spec.license       = 'MIT'
  spec.files         = included_files
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'money'
  spec.add_dependency 'paypal-sdk-rest', '~> 1.6.0'

  spec.add_development_dependency 'bundler', "~> 1.5"
  spec.add_development_dependency 'rake'
end