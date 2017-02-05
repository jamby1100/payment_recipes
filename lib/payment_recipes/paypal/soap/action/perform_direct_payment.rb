module PaymentRecipes
  module PayPal
    module SOAP
      module Action
        class PerformDirectPayment < PaymentRecipes::Utils::Action
          variable :details, "Hash"
          variable :intent, "Symbol"

          def perform
            prepare_soap_api
            modify_details
            perform_request

            if response.success?
              load_transaction
            end

            response
          end

          def prepare_soap_api
            store(:api) do
              ::PaymentRecipes::PayPal::SOAP::Settings.api
            end
          end

          def modify_details
            unless [:sale, :authorize].include?(intent)
              raise Exception, "Allowed values for intent: :sale, :authorize"
            end

            store(:direct_payment_details) do
              payment_action = if intent == :sale
                                 'Sale'
                               elsif intent == :authorize
                                 'Authorization'
                               end

              details[:DoDirectPaymentRequestDetails][:PaymentAction] = payment_action

              details
            end
          end

          def perform_request
            do_direct_payment = api.build_do_direct_payment(direct_payment_details)

            store(:response) do
              api.do_direct_payment(do_direct_payment)
            end
          end

          def load_transaction
            store(:transaction) do
              ::PaymentRecipes::PayPal::SOAP::Transaction.find(response.transaction_id)
            end
          end
        end
      end
    end
  end
end