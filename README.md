Payment Recipes (payment_recipes) v 1.1.0
=========================================

Wrapper classes and utilities to speed up payment gateway integration and report generation. 

- Currently supports some of the commonly used PayPal Ruby REST SDK actions and resources. 
- Currently supports some of the commonly used PayPal Ruby SOAP SDK actions and resources.
- Automatically converts amounts to money format using the Money gem.
- Links resources together automatically
- Reload and expand options for entities to fetch latest version
- Automatically fetches and connects linked resources if missing

### Installation

PaymentRecipes (payment_recipes) is available as a RubyGem:

```bash
$ gem install payment_recipes
```

### Gemfile

~~~ ruby
...

gem 'payment_recipes', '~> 1.1.0'

...
~~~

## Usage: PayPal REST

### Settings

~~~ ruby
client_id = "..."
client_secret = "..."

PaymentRecipes::PayPal::REST::Settings.configure(
  client_id: client_id,
  client_secret: client_secret,
  live: false
)
~~~


### Payment (Wrapper)

~~~ ruby
# Specific Payment
payment_id = 'PAY-************************'
payment = PaymentRecipes::PayPal::REST::Payment.find(payment_id)

puts payment.refunds
puts payment.refund
puts payment.authorizations
puts payment.authorization
puts payment.captures
puts payment.capture
puts payment.sale.transaction_fee

# Payment History
payments = PaymentRecipes::PayPal::REST::Payment.history(count: 5, expand: true)
puts payments.first.id

# Access Raw Version
puts payment.raw_payment
# => <PayPal::SDK::REST::Payment>
~~~


### Sale (Wrapper)

~~~ ruby
sale_id = "*****************"
sale = PaymentRecipes::PayPal::REST::Sale.find(sale_id)

sale.total
# => <Money>

sale.transaction_fee
# => <Money>

sale.payment
# => <PaymentRecipes::PayPal::Payment>
~~~


### Authorization (Wrapper)

~~~ ruby
authorization_id = "*****************"
authorization = PaymentRecipes::PayPal::REST::Authorization.find(authorization_id)

puts authorization.total
# => <Money>

puts authorization.payment
# => <PaymentRecipes::PayPal::Payment>

puts authorization.payment_mode

puts authorization.captures
puts authorization.capture

puts authorization.state
# => :captured

puts authorization.captured?
~~~


### Capture (Wrapper)

~~~ ruby
capture_id = "*****************"
capture = PaymentRecipes::PayPal::REST::Capture.find(capture_id)

puts capture.total
# => <Money>

puts capture.state
# => :completed

puts capture.completed?
~~~


### Refund (Wrapper)

~~~ ruby
refund_id = "*****************"
refund = PaymentRecipes::PayPal::REST::Refund.find(refund_id)

puts refund.sale
puts refund.capture
puts refund.payment
puts refund.total
puts refund.state
~~~

### Capture Authorization (Action)

~~~ ruby
authorization_id = "*****************"
authorization = PaymentRecipes::PayPal::REST::Authorization.find(authorization_id)

action = PaymentRecipes::PayPal::REST::Action::CaptureAuthorization.prepare(authorization: authorization)
action.execute

puts action.authorization.capture
# => <PaymentRecipes::PayPal::Capture 
#       total=$20.00 
#       state=completed 
#       id=*****************>
~~~


### Create Payment (Action) - Sale / Direct

~~~ ruby
# Using an example credit card
attributes = {
  "payer" =>  {
    "payment_method" =>  "credit_card",
    "funding_instruments" =>  [ 
      {
        "credit_card" =>  {
          "type" =>  "visa",
          "number" =>  "4111111111111111",
          "expire_month" =>  "11", "expire_year" =>  "2018",
          "cvv2" =>  "874",
          "first_name" =>  "Sample", "last_name" =>  "Customer",
          "billing_address" =>  {
            "line1" =>  "Sample Line 1",
            "city" =>  "Sample City",
            "state" =>  "OH",
            "postal_code" =>  "43210", "country_code" =>  "US" 
          } 
        } 
      } 
    ] 
  }
}

action = PaymentRecipes::PayPal::REST::Action::CreatePayment.prepare(
  intent: :sale,
  amount: Money.new(100_00, "USD"),
  description: "Sample Sale Transaction",
  attributes: attributes
)

action.execute

puts action.payment
# => <PaymentRecipes::PayPal::REST::Payment 
#       intent=sale 
#       state=approved 
#       id=PAY-************************>

puts action.sale
# => <PaymentRecipes::PayPal::REST::Sale 
#       total=$100.00 
#       state=completed 
#       id=*****************>
~~~

### Create Payment (Action) - Authorization / Direct

~~~ ruby
# Using an example credit card
attributes = {
  "payer" =>  {
    "payment_method" =>  "credit_card",
    "funding_instruments" =>  [ 
      {
        "credit_card" =>  {
          "type" =>  "visa",
          "number" =>  "4111111111111111",
          "expire_month" =>  "11", "expire_year" =>  "2018",
          "cvv2" =>  "874",
          "first_name" =>  "Sample", "last_name" =>  "Customer",
          "billing_address" =>  {
            "line1" =>  "Sample Line 1",
            "city" =>  "Sample City",
            "state" =>  "OH",
            "postal_code" =>  "43210", "country_code" =>  "US" 
          } 
        } 
      } 
    ] 
  }
}

action = PaymentRecipes::PayPal::REST::Action::CreatePayment.prepare(
  intent: :authorize,
  amount: Money.new(100_00, "USD"),
  description: "Sample Authorization Transaction",
  attributes: attributes
)

action.execute

puts action.payment
# => <PaymentRecipes::PayPal::REST::Payment 
#       intent=sale 
#       state=approved 
#       id=PAY-************************>

# => <PaymentRecipes::PayPal::REST::Payment 
#       intent=authorize 
#       state=approved 
#       id=PAY-************************> 

puts action.authorization
# => <PaymentRecipes::PayPal::REST::Authorization 
#       total=$100.00 
#       state=authorized 
#       id=*****************>

authorization = action.authorization

action = PaymentRecipes::PayPal::REST::Action::CaptureAuthorization.prepare(authorization: authorization)
action.execute

puts action.authorization.capture
~~~


### Execute Payment (Action) - Sale / Express Checkout

~~~ ruby
attributes = {
  "payer" =>  {
    "payment_method" =>  "paypal"
  },
  "redirect_urls" => {
    "return_url" => "https://localhost:3000/return",
    "cancel_url" => "https://localhost:3000/cancel"
  }
}

action = PaymentRecipes::PayPal::REST::Action::CreatePayment.prepare(
  intent: :sale,
  amount: Money.new(100_00, "USD"),
  description: "Sample Sale Transaction",
  attributes: attributes
)

action.execute

puts action.redirect_url
# => https://www.sandbox.paypal.com/cgi-bin/webscr?
#       cmd=_express-checkout&
#       token=EC-*****************

# https://localhost:3000/return?
#       paymentId=PAY-************************&
#       token=EC-*****************&
#       PayerID=*************

payment_id = "PAY-************************"
payment = PaymentRecipes::PayPal::REST::Payment.find(payment_id)
payer_id = "*************"

action = PaymentRecipes::PayPal::REST::Action::ExecutePayment.prepare(
           payment: payment, 
           payer_id: payer_id)

action.execute

puts action.payment
# => <PaymentRecipes::PayPal::Payment 
#       intent=sale 
#       state=approved 
#       id=PAY-************************>
~~~


### Execute Payment (Action) - Authorization / Express Checkout

~~~ ruby
attributes = {
  "payer" =>  {
    "payment_method" =>  "paypal"
  },
  "redirect_urls" => {
    "return_url" => "https://localhost:3000/return",
    "cancel_url" => "https://localhost:3000/cancel"
  }
}

action = PaymentRecipes::PayPal::REST::Action::CreatePayment.prepare(
  intent: :authorize,
  amount: Money.new(100_00, "USD"),
  description: "Sample Authorization Transaction",
  attributes: attributes
)

action.execute

puts action.redirect_url
# => https://www.sandbox.paypal.com/cgi-bin/webscr?
#       cmd=_express-checkout&
#       token=EC-*****************

# https://localhost:3000/return?
#       paymentId=PAY-************************&
#       token=EC-*****************&
#       PayerID=*************

payment_id = "PAY-************************"
payment = PaymentRecipes::PayPal::REST::Payment.find(payment_id)
payer_id = "*************"

action = PaymentRecipes::PayPal::REST::Action::ExecutePayment.prepare(
           payment: payment, 
           payer_id: payer_id)

action.execute

puts action.payment
# => <PaymentRecipes::PayPal::Payment 
#       intent=sale 
#       state=approved 
#       id=PAY-************************>

puts action.authorization
# => <PaymentRecipes::PayPal::REST::Authorization 
#       total=$100.00 
#       state=authorized 
#       id=*****************>

authorization = action.authorization

action = PaymentRecipes::PayPal::REST::Action::CaptureAuthorization.prepare(authorization: authorization)
action.execute

puts action.authorization
# => <PaymentRecipes::PayPal::REST::Authorization 
#       total=$100.00 
#       state=captured 
#       id=*****************>

puts action.authorization.capture
# => <PaymentRecipes::PayPal::REST::Capture 
#       total=$100.00 
#       state=completed 
#       id=*****************>
~~~

### Refund Capture (Action)

~~~ ruby
capture_id = '*****************'
capture = PaymentRecipes::PayPal::REST::Capture.find(capture_id)

# => <PaymentRecipes::PayPal::REST::Capture 
#       total=$100.00 
#       state=completed 
#       id=*****************>

action = PaymentRecipes::PayPal::REST::Action::RefundCapture.prepare(capture: capture)
action.execute

action.capture
# => <PaymentRecipes::PayPal::Capture 
#       total=$100.00 
#       state=refunded 
#       id=*****************>
~~~

### Refund Sale (Action)

~~~ ruby
sale_id = '*****************'
sale = PaymentRecipes::PayPal::REST::Sale.find(sale_id)
# => <PaymentRecipes::PayPal::REST::Sale 
#       total=$100.00 
#       state=completed 
#       id=*****************>

action = PaymentRecipes::PayPal::REST::Action::RefundSale.prepare(sale: sale)
action.execute

action.sale
# => <PaymentRecipes::PayPal::Sale 
#       total=$100.00 
#       state=refunded 
#       id=*****************>
~~~

### Void Authorization (Action)

~~~ ruby
authorization_id = '*****************'
authorization = PaymentRecipes::PayPal::REST::Authorization.find(authorization_id)
# => <PaymentRecipes::PayPal::REST::Authorization 
#       total=$100.00 
#       state=authorized 
#       id=*****************>

action = PaymentRecipes::PayPal::REST::Action::VoidAuthorization.prepare(authorization: authorization)
action.execute

puts action.authorization
# => <PaymentRecipes::PayPal::REST::Authorization 
#       total=$100.00 
#       state=voided 
#       id=*****************> 
~~~

## Usage: PayPal SOAP

### Settings

~~~ ruby
app_id = "..."
username = "..."
password = "..."
signature = "..."

PaymentRecipes::PayPal::SOAP::Settings.configure(
  live: false,
  app_id: app_id,
  username: username,
  password: password,
  signature: signature
)
~~~

### Transaction (Wrapper)
~~~ ruby
transaction_id = '*****************'
transaction = PaymentRecipes::PayPal::SOAP::Transaction.find(transaction_id)

puts transaction
# => <PaymentRecipes::PayPal::SOAP::Transaction 
#       type=web-accept 
#       payment_type=instant 
#       payment_status=Completed 
#       id=*****************>

transaction.gross_amount
# => #<Money fractional:100 currency:USD> 

transaction.payment_item_amount
# => #<Money fractional:100 currency:USD>

transaction.fee_amount
# =>  #<Money fractional:33 currency:USD>

transaction.tax_amount
# => #<Money fractional:0 currency:USD> 

transaction.transaction_type
# => 'web-accept'

transaction.payment_type
# => 'instant'

transaction.payment_status
# => 'Completed'

transaction.complete?
# => true

transaction.payment_date
# => 201X-XX-XX 22:38:30 +XXXX
~~~

### Perform Direct Payment (Action) - Sale
~~~ ruby
details = {
  :DoDirectPaymentRequestDetails => {
    :PaymentDetails => {
      :OrderTotal => {
        :currencyID => 'USD',
        :value => '1' },
      :NotifyURL => 'http://localhost:3000/samples/merchant/ipn_notify' },
    :CreditCard => {
      :CreditCardType => 'Visa',
      :CreditCardNumber => '4904202183894535',
      :ExpMonth => 12,
      :ExpYear => 2022,
      :CVV2 => '962' 
    } 
  } 
}

action = PaymentRecipes::PayPal::SOAP::Action::PerformDirectPayment.prepare(
           details: details,
           intent: :sale
         )

action.execute

puts action.response.success?
# => true

puts action.response.transaction_id
# => "*****************"

puts action.transaction
# =>  <PaymentRecipes::PayPal::SOAP::Transaction 
#       type=web-accept 
#       payment_type=instant 
#       payment_status=Completed 
#       id=*****************>

puts action.transaction.fee_amount
# => #<Money fractional:33 currency:USD>
~~~

### Create Express Checkout (Action) - Sale

~~~ruby
details = {
  :SetExpressCheckoutRequestDetails => {
    :ReturnURL => 'http://localhost:3000/merchant/do_express_checkout_payment',
    :CancelURL => 'http://localhost:3000/merchant/set_express_checkout',
    :PaymentDetails => [{
      :OrderTotal => {
        :currencyID => 'USD',
        :value => '8.27' },
      :ItemTotal => {
        :currencyID => 'USD',
        :value => '5.27' },
      :ShippingTotal => {
        :currencyID => 'USD',
        :value => '3.0' },
      :TaxTotal => {
        :currencyID => 'USD',
        :value => '0' },
      :NotifyURL => 'http://localhost:3000/merchant/ipn_notify',
      :ShipToAddress => {
        :Name => 'John Doe',
        :Street1 => '1 Main St',
        :CityName => 'San Jose',
        :StateOrProvince => 'CA',
        :Country => 'US',
        :PostalCode => '95131' },
      :ShippingMethod => 'UPSGround',
      :PaymentDetailsItem => [{
        :Name => 'Item Name',
        :Quantity => 1,
        :Amount => {
          :currencyID => 'USD',
          :value => '5.27' },
        :ItemCategory => 'Physical' }]
      }] } }

action = PaymentRecipes::PayPal::SOAP::Action::CreateExpressCheckout.prepare(
           details: details, 
           intent: :sale)

action.execute

puts action.response.token
# => "EC-*****************"

puts action.redirect_url
# => https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&token=EC-*****************
~~~

### Do Express Checkout (Action) - Sale
~~~ ruby
token = "EC-*****************"
payer_id = "*************"

details = {
  :OrderTotal => {
    :currencyID => 'USD',
    :value => '8.27' 
  },
  :NotifyURL => 'https://localhost:3000/merchant/ipn_notify' 
}

intent = :sale

action = PaymentRecipes::PayPal::SOAP::Action::ExecuteExpressCheckout.prepare(
           token: token,
           payer_id: payer_id,
           details: details,
           intent: intent
         )
         
action.execute

puts action.transaction
# => <PaymentRecipes::PayPal::SOAP::Transaction 
#       type=express-checkout 
#       payment_type=instant 
#       payment_status=Completed 
#       id=*****************>
~~~

### Perform Direct Payment (Action) - Authorization
~~~ ruby
details = {
  :DoDirectPaymentRequestDetails => {
    :PaymentDetails => {
      :OrderTotal => {
        :currencyID => 'USD',
        :value => '1' },
      :NotifyURL => 'http://localhost:3000/samples/merchant/ipn_notify' },
    :CreditCard => {
      :CreditCardType => 'Visa',
      :CreditCardNumber => '4904202183894535',
      :ExpMonth => 12,
      :ExpYear => 2022,
      :CVV2 => '962' 
    } 
  } 
}

action = PaymentRecipes::PayPal::SOAP::Action::PerformDirectPayment.prepare(
           details: details,
           intent: :authorize
         )

action.execute

puts action.response.success?
# => true

puts action.response.transaction_id
# => "*****************"

puts action.transaction
# =>  <PaymentRecipes::PayPal::SOAP::Transaction 
#       type=web-accept 
#       payment_type=instant 
#       payment_status=Pending [authorization] 
#       id=*****************>

puts action.transaction.pending?
# => true
~~~

### Create Express Checkout (Action) - Authorization

~~~ruby
details = {
  :SetExpressCheckoutRequestDetails => {
    :ReturnURL => 'http://localhost:3000/merchant/do_express_checkout_payment',
    :CancelURL => 'http://localhost:3000/merchant/set_express_checkout',
    :PaymentDetails => [{
      :OrderTotal => {
        :currencyID => 'USD',
        :value => '8.27' },
      :ItemTotal => {
        :currencyID => 'USD',
        :value => '5.27' },
      :ShippingTotal => {
        :currencyID => 'USD',
        :value => '3.0' },
      :TaxTotal => {
        :currencyID => 'USD',
        :value => '0' },
      :NotifyURL => 'http://localhost:3000/merchant/ipn_notify',
      :ShipToAddress => {
        :Name => 'John Doe',
        :Street1 => '1 Main St',
        :CityName => 'San Jose',
        :StateOrProvince => 'CA',
        :Country => 'US',
        :PostalCode => '95131' },
      :ShippingMethod => 'UPSGround',
      :PaymentDetailsItem => [{
        :Name => 'Item Name',
        :Quantity => 1,
        :Amount => {
          :currencyID => 'USD',
          :value => '5.27' },
        :ItemCategory => 'Physical' }]
      }] } }

action = PaymentRecipes::PayPal::SOAP::Action::CreateExpressCheckout.prepare(
           details: details, 
           intent: :authorize)

action.execute

puts action.response.token
# => "EC-*****************"

puts action.redirect_url
# => https://www.sandbox.paypal.com/webscr?
#      cmd=_express-checkout&
#      token=EC-*****************
~~~

### Do Express Checkout (Action) - Authorization
~~~ ruby
token = "EC-*****************"
payer_id = "*************"

details = {
  :OrderTotal => {
    :currencyID => 'USD',
    :value => '8.27' 
  },
  :NotifyURL => 'https://localhost:3000/merchant/ipn_notify' 
}

intent = :authorize

action = PaymentRecipes::PayPal::SOAP::Action::ExecuteExpressCheckout.prepare(
           token: token,
           payer_id: payer_id,
           details: details,
           intent: intent
         )
         
action.execute

puts action.transaction
# => <PaymentRecipes::PayPal::SOAP::Transaction 
#       type=express-checkout 
#       payment_type=instant 
#       payment_status=Pending [authorization] 
#       id=*****************>
~~~

### Perform Capture (Action)

~~~ ruby
authorization_id = "*****************"
amount = { :currencyID => 'USD', :value => '1' }

action = PaymentRecipes::PayPal::SOAP::Action::CaptureAuthorization.prepare(
           authorization_id: authorization_id,
           amount: amount)

action.execute

puts action.response.success?
# => true

puts action.authorization_id
# => *****************

puts action.capture_id
# => *****************

puts action.authorization_transaction
# => <PaymentRecipes::PayPal::SOAP::Transaction 
#       type=web-accept 
#       payment_type=instant 
#       payment_status=Completed 
#       id=*****************>

puts action.capture_transaction
# => <PaymentRecipes::PayPal::SOAP::Transaction 
#       type=web-accept 
#       payment_type=instant 
#       payment_status=Completed 
#       id=*****************>
~~~

License
-------
Copyright (c) 2016-2017 Joshua Arvin Lat

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.