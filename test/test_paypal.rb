require 'minitest/autorun'
require 'test_helper'
require 'payment_recipes'

class TestPayPal < Minitest::Test
  def test_payment
    PaymentRecipes::PayPal::Settings.configure(
      client_id: KEYS['PAYPAL_CLIENT_ID'],
      client_secret: KEYS['PAYPAL_CLIENT_SECRET'],
      mode: :sandbox
    )

    payments = PaymentRecipes::PayPal::Payment.history(count: 5, expand: true)

    assert payments.map(&:class).uniq.first == PaymentRecipes::PayPal::Payment
  end
end