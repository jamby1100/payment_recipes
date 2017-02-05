"""
NOTES: Response Structure (action.response)

PayPal::SDK::Merchant::DataTypes::DoExpressCheckoutPaymentResponseType
   ├── Ack: Success
   ├── Build: ***
   ├── CorrelationID: ***
   ├── DoExpressCheckoutPaymentResponseDetails: PayPal::SDK::Merchant::DataTypes::DoExpressCheckoutPaymentResponseDetailsType
   │   ├── CoupledPaymentInfo: PayPal::SDK::Core::API::DataTypes::ArrayWithBlock
   │   │   └── 0: #<PayPal::SDK::Merchant::DataTypes::CoupledPaymentInfoType:0x007fba1a527138>
   │   │
   │   ├── PaymentInfo: PayPal::SDK::Core::API::DataTypes::ArrayWithBlock
   │   │   └── 0: PayPal::SDK::Merchant::DataTypes::PaymentInfoType
   │   │       ├── ExchangeRate: nil
   │   │       ├── FeeAmount: PayPal::SDK::Merchant::DataTypes::BasicAmountType
   │   │       │   ├── currencyID: USD
   │   │       │   └── value: 0.36
   │   │       │
   │   │       ├── GrossAmount: PayPal::SDK::Merchant::DataTypes::BasicAmountType
   │   │       │   ├── currencyID: USD
   │   │       │   └── value: 2.00
   │   │       │
   │   │       ├── ParentTransactionID: nil
   │   │       ├── PaymentDate: 2017-02-05T17:34:13+00:00
   │   │       ├── PaymentStatus: Completed
   │   │       ├── PaymentType: instant
   │   │       ├── PendingReason: none
   │   │       ├── ProtectionEligibility: Eligible
   │   │       ├── ProtectionEligibilityType: ItemNotReceivedEligible,UnauthorizedPaymentEligible
   │   │       ├── ReasonCode: none
   │   │       ├── ReceiptID: nil
   │   │       ├── SellerDetails: PayPal::SDK::Merchant::DataTypes::SellerDetailsType
   │   │       │   └── SecureMerchantAccountID: ***
   │   │       │
   │   │       ├── TaxAmount: PayPal::SDK::Merchant::DataTypes::BasicAmountType
   │   │       │   ├── currencyID: USD
   │   │       │   └── value: 0.00
   │   │       │
   │   │       ├── TransactionID: ***
   │   │       └── TransactionType: express-checkout
   │   │    
   │   ├── SuccessPageRedirectRequested: false
   │   └── Token: ***
   │
   ├── Timestamp: ***
   └── Version: ***
"""

module PaymentRecipes
  module PayPal
    module SOAP
      module Action
        class ExecuteExpressCheckout < PaymentRecipes::Utils::Action
          variable :token, "String"
          variable :payer_id, "String"
          variable :details, "Hash"
          variable :intent, "Symbol"

          def perform
            prepare_soap_api
            modify_details
            do_express_checkout

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

            store(:express_checkout_details) do
              payment_action = if intent == :sale
                                 'Sale'
                               elsif intent == :authorize
                                 'Authorization'
                               end

              {
                :DoExpressCheckoutPaymentRequestDetails => {
                  :PaymentAction => payment_action,
                  :Token => token,
                  :PayerID => payer_id,
                  :PaymentDetails => [details] 
                } 
              }
            end
          end

          def response
            do_express_checkout_response
          end

          def do_express_checkout
            do_express_checkout_payment = api.build_do_express_checkout_payment(express_checkout_details)

            store(:do_express_checkout_response) do
              response = api.do_express_checkout_payment(do_express_checkout_payment)

              unless response.success?
                @error = response.errors

                response = nil
              end

              response
            end
          end

          def load_transaction
            store(:transaction) do
              transaction_id = response.do_express_checkout_payment_response_details.payment_info.first.transaction_id
              
              ::PaymentRecipes::PayPal::SOAP::Transaction.find(transaction_id)
            end
          end
        end
      end
    end
  end
end