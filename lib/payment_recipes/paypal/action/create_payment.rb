module PaymentRecipes
  module PayPal
    module Action
      class CreatePayment < PaymentRecipes::Utils::Action
        variable :intent, ::Symbol
        variable :attributes, ::Hash
        variable :amount, ::Money
        variable :description, ::String

        include ::PaymentRecipes::Utils::Converters

        def perform
          unless [:sale, :authorize].include?(@intent)
            raise Exception, "Allowed values for intent: :sale, :authorize"
          end

          @paypal_payment = ::PayPal::SDK::REST::Payment.new(payment_attributes)
          @paypal_payment.create

          @payment = ::PaymentRecipes::PayPal::Payment.find(@paypal_payment.id)

          @payment
        end

        def payment
          @payment
        end

        def paypal_payment
          @paypal_payment
        end

        def redirect_url
          paypal_payment.links.select { |link| link.rel == 'approval_url' }.first.href rescue nil
        end

        def sale
          return nil unless @payment

          @payment.sale
        end

        def authorization
          return nil unless @payment

          @payment.authorization
        end

        def payment_attributes
          {
            "intent" => convert_to_string(@intent),
            "transactions" => [
              {
                "amount" => {
                  "total" => @amount.to_s,
                  "currency" => @amount.currency.iso_code
                },
                "description" => @description
              }
            ]
          }.merge(attributes)
        end
      end
    end
  end
end