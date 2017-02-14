module PaymentRecipes
  module PayPal
    module SOAP
      module Action
        class CreateExpressCheckout < PaymentRecipes::Utils::Action
          variable :details, "Hash"
          variable :intent, "Symbol"

          def perform
            prepare_soap_api
            modify_details
            set_express_checkout

            get_express_checkout_url
            get_express_checkout_alternative_redirect_url

            express_checkout_redirect_url
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

            store(:express_checkout_details) do
              payment_action = if intent == :sale
                                 'Sale'
                               elsif intent == :authorize
                                 'Authorization'
                               end

              details[:SetExpressCheckoutRequestDetails][:PaymentDetails][0][:PaymentAction] = payment_action

              details
            end
          end

          def set_express_checkout
            set_express_checkout = api.build_set_express_checkout(express_checkout_details)

            store(:set_express_checkout_response) do
              response = api.set_express_checkout(set_express_checkout)

              unless response.success?
                @error = response.errors

                response = nil
              end

              response
            end
          end

          def response
            set_express_checkout_response
          end

          def get_express_checkout_url
            store(:express_checkout_redirect_url) do
              if set_express_checkout_response
                api.express_checkout_url(set_express_checkout_response)
              end
            end
          end

          def redirect_url
            express_checkout_redirect_url
          end

          def get_express_checkout_alternative_redirect_url
            store(:express_checkout_alternative_redirect_url) do
              paypal_base_url = if api.config.mode == "sandbox"
                                  "https://www.sandbox.paypal.com"
                                else
                                  "https://www.paypal.com"
                                end

              "#{ paypal_base_url }/webapps/xoonboarding?token=#{ response.token }&useraction=commit"
            end
          end

          def alternative_redirect_url
            express_checkout_alternative_redirect_url
          end
        end
      end
    end
  end
end