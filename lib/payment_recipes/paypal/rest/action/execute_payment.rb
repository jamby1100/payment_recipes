module PaymentRecipes
  module PayPal
    module REST
      module Action
        class ExecutePayment < PaymentRecipes::Utils::Action
          variable :payment, "PaymentRecipes::PayPal::REST::Payment"
          variable :payer_id, "String"

          def perform
            @payment.raw_payment.execute( :payer_id => payer_id )
            @payment.reload!

            @payment
          end

          def authorization
            return nil unless payment

            payment.authorization
          end
        end
      end
    end
  end
end
