module PaymentRecipes
  module PayPal
    module Action
      class ExecutePayment < PaymentRecipes::Utils::Action
        variable :payment, PaymentRecipes::PayPal::Payment
        variable :payer_id, String

        def perform
          @payment.raw_payment.execute( :payer_id => payer_id )
          @payment.reload!

          @payment
        end
      end
    end
  end
end
