Payment Recipes (payment_recipes)
=======================================

Wrapper classes and utilities to speed up payment gateway integration and report generation. 

- Currently supports some of the commonly used PayPal Ruby SDK actions and resources. 
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

gem 'payment_recipes'

...
~~~

## Usage: PayPal

### Settings

~~~ ruby
client_id = "..."
client_secret = "..."

PaymentRecipes::PayPal::Settings.configure(
  client_id: client_id,
  client_secret: client_secret,
  mode: :sandbox
)
~~~


### Payment (Wrapper)

~~~ ruby
# Specific Payment
payment_id = 'PAY-************************'
payment = PaymentRecipes::PayPal::Payment.find(payment_id)

puts payment.refunds
puts payment.refund
puts payment.authorizations
puts payment.authorization
puts payment.captures
puts payment.capture
puts payment.sale.transaction_fee

# Payment History
payments = PaymentRecipes::PayPal::Payment.history(count: 5, expand: true)
puts payments.first.id

# Access Raw Version
puts payment.raw_payment
# => <PayPal::SDK::REST::Payment>
~~~


### Sale (Wrapper)

~~~ ruby
sale_id = "*****************"
sale = PaymentRecipes::PayPal::Sale.find(sale_id)

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
authorization = PaymentRecipes::PayPal::Authorization.find(authorization_id)

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
capture = PaymentRecipes::PayPal::Capture.find(capture_id)

puts capture.total
# => <Money>

puts capture.state
# => :completed

puts capture.completed?
~~~


### Refund (Wrapper)

~~~ ruby
refund_id = "*****************"
refund = PaymentRecipes::PayPal::Refund.find(refund_id)

puts refund.sale
puts refund.capture
puts refund.payment
puts refund.total
puts refund.state
~~~

### Capture Authorization (Action)

~~~ ruby
authorization_id = "*****************"
authorization = PaymentRecipes::PayPal::Authorization.find(authorization_id)

action = PaymentRecipes::PayPal::Action::CaptureAuthorization.prepare(authorization: authorization)
action.perform

puts action.authorization.capture
# => <PaymentRecipes::PayPal::Capture total=$20.00 state=completed id=*****************>
~~~


### Create Payment (Action)

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

action = PaymentRecipes::PayPal::Action::CreatePayment.prepare(
  intent: :sale,
  amount: Money.new(100_00, "USD"),
  description: "Sample Sale Transaction",
  attributes: attributes
)

action.perform

puts action.payment
# => <PaymentRecipes::PayPal::Payment intent=sale state=approved id=PAY-************************>

puts action.sale
# => <PaymentRecipes::PayPal::Sale total=$100.00 state=completed id=*****************>
~~~


### Execute Payment (Action)

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

action = PaymentRecipes::PayPal::Action::CreatePayment.prepare(
  intent: :sale,
  amount: Money.new(100_00, "USD"),
  description: "Sample Sale Transaction",
  attributes: attributes
)

action.perform

puts action.redirect_url
# => https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=EC-*****************

# https://localhost:3000/return?paymentId=PAY-************************&token=EC-*****************&PayerID=*************

payment_id = "PAY-************************"
payment = PaymentRecipes::PayPal::Payment.find(payment_id)
payer_id = "*************"

action = PaymentRecipes::PayPal::Action::ExecutePayment.prepare(payment: payment, payer_id: payer_id)
action.perform

puts action.payment
# => <PaymentRecipes::PayPal::Payment intent=sale state=approved id=PAY-************************>
~~~

### Refund Capture (Action)

~~~ ruby
capture_id = '*****************'
capture = PaymentRecipes::PayPal::Capture.find(capture_id)

action = PaymentRecipes::PayPal::Action::RefundCapture.prepare(capture: capture)
action.perform

action.capture
# => <PaymentRecipes::PayPal::Capture total=$20.00 state=refunded id=*****************>
~~~

### Refund Sale (Action)

~~~ ruby
sale_id = '*****************'
sale = PaymentRecipes::PayPal::Sale.find(sale_id)

action = PaymentRecipes::PayPal::Action::RefundSale.prepare(sale: sale)
action.perform

action.sale
# => <PaymentRecipes::PayPal::Sale total=$100.00 state=refunded id=*****************>
~~~

### Void Authorization (Action)

~~~ ruby
authorization_id = '*****************'
authorization = PaymentRecipes::PayPal::Authorization.find(authorization_id)

action = PaymentRecipes::PayPal::Action::VoidAuthorization.prepare(authorization: authorization)
action.perform
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