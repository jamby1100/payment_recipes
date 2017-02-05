# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'payment_recipes/version'

included_files = [
  'version',
  'utils/action',
  'utils/converters',
  'utils/equality',
  'paypal/rest/settings',
  'paypal/rest/authorization',
  'paypal/rest/capture',
  'paypal/rest/payer',
  'paypal/rest/payment',
  'paypal/rest/refund',
  'paypal/rest/sale',
  'paypal/rest/transaction',
  'paypal/rest/action/capture_authorization',
  'paypal/rest/action/create_payment',
  'paypal/rest/action/execute_payment',
  'paypal/rest/action/refund_capture',
  'paypal/rest/action/refund_sale',
  'paypal/rest/action/void_authorization',
  'paypal/soap/settings',
  'paypal/soap/transaction',
  'paypal/soap/action/perform_direct_payment',
  'paypal/soap/action/capture_authorization',
  'paypal/soap/action/create_express_checkout_payment',
  'paypal/soap/action/execute_express_checkout_payment'
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
  spec.add_dependency 'paypal-sdk-merchant', '~> 1.106.1'

  spec.add_development_dependency 'bundler', "~> 1.5"
  spec.add_development_dependency 'rake'
end