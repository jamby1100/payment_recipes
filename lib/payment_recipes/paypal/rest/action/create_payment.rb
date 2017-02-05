module PaymentRecipes
  module PayPal
    module REST
      module Action
        class CreatePayment < PaymentRecipes::Utils::Action
          variable :intent, "Symbol"
          variable :attributes, "Hash"
          variable :amount, "Money"
          variable :description, "String"

          include ::PaymentRecipes::Utils::Converters

          def perform
            unless [:sale, :authorize].include?(intent)
              raise Exception, "Allowed values for intent: :sale, :authorize"
            end

            create_paypal_payment!
            find_payment!

            payment
          end

          def create_paypal_payment!
            store(:paypal_payment) do
              new_paypal_payment = ::PayPal::SDK::REST::Payment.new(payment_attributes)
              new_paypal_payment.create

              new_paypal_payment
            end
          end

          def find_payment!
            store(:payment) do
              ::PaymentRecipes::PayPal::REST::Payment.find(paypal_payment.id)
            end
          end

          def redirect_url
            paypal_payment.links.select { |link| link.rel == 'approval_url' }.first.href rescue nil
          end

          def sale
            return nil unless payment

            payment.sale
          end

          def authorization
            return nil unless payment

            payment.authorization
          end

          def payment_attributes
            {
              "intent" => convert_to_string(intent),
              "transactions" => [
                {
                  "amount" => {
                    "total" => amount.to_s,
                    "currency" => amount.currency.iso_code
                  },
                  "description" => description
                }
              ]
            }.merge(attributes)
          end
        end
      end
    end
  end
end