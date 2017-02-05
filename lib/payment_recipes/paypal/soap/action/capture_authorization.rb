"""
PayPal::SDK::Merchant::DataTypes::DoCaptureResponseType
   ├── Ack: Success
   ├── Build: ***
   ├── CorrelationID: ***
   ├── DoCaptureResponseDetails: PayPal::SDK::Merchant::DataTypes::DoCaptureResponseDetailsType
   │   ├── AuthorizationID: ***
   │   └── PaymentInfo: PayPal::SDK::Merchant::DataTypes::PaymentInfoType
   │       ├── ExchangeRate: nil
   │       ├── FeeAmount: PayPal::SDK::Merchant::DataTypes::BasicAmountType
   │       │   ├── currencyID: USD
   │       │   └── value: 0.33
   │       │
   │       ├── GrossAmount: PayPal::SDK::Merchant::DataTypes::BasicAmountType
   │       │   ├── currencyID: USD
   │       │   └── value: 1.00
   │       │
   │       ├── ParentTransactionID: ***
   │       ├── PaymentDate: 2017-02-05T18:15:36+00:00
   │       ├── PaymentStatus: Completed
   │       ├── PaymentType: instant
   │       ├── PendingReason: none
   │       ├── ProtectionEligibility: Ineligible
   │       ├── ProtectionEligibilityType: None
   │       ├── ReasonCode: none
   │       ├── ReceiptID: 5351-7638-9795-5628
   │       ├── TaxAmount: PayPal::SDK::Merchant::DataTypes::BasicAmountType
   │       │   ├── currencyID: USD
   │       │   └── value: 0.00
   │       │
   │       ├── TransactionID: ***
   │       └── TransactionType: web-accept
   │    
   ├── Timestamp: 2017-02-05T18:15:37+00:00
   └── Version: 106.0
"""

module PaymentRecipes
  module PayPal
    module SOAP
      module Action
        class CaptureAuthorization < PaymentRecipes::Utils::Action
          variable :authorization_id, "String"
          variable :amount, "Hash"

          def perform
            prepare_soap_api

            do_capture_authorization

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

          def response
            do_capture_response
          end

          def do_capture_authorization
            do_capture = api.build_do_capture({
              :AuthorizationID => authorization_id,
              :Amount => amount,
              :CompleteType => "Complete" })

            store(:do_capture_response) do
              capture_response = api.do_capture(do_capture)

              unless capture_response.success?
                @error = capture_response.errors

                capture_response = nil
              end

              capture_response
            end
          end

          def load_transaction
            store(:authorization_transaction) do
              ::PaymentRecipes::PayPal::SOAP::Transaction.find(authorization_id)
            end

            store(:capture_transaction) do
              ::PaymentRecipes::PayPal::SOAP::Transaction.find(capture_id)
            end
          end

          def capture_id
            response.do_capture_response_details.payment_info.transaction_id
          end
        end
      end
    end
  end
end