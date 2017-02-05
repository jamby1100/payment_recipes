module PaymentRecipes
  module PayPal
    module SOAP
      class Transaction
        attr_reader :raw_transaction

        attr_reader :id
        attr_reader :correlation_id
        attr_reader :timestamp
        attr_reader :transaction_type

        attr_reader :gross_amount
        attr_reader :fee_amount
        attr_reader :tax_amount
        attr_reader :payment_item_amount

        attr_reader :payment_date
        attr_reader :payment_type
        attr_reader :payment_status
        attr_reader :pending_reason

        attr_reader :parent_transaction_id

        include ::PaymentRecipes::Utils::Converters
        include ::PaymentRecipes::Utils::Equality

        def initialize(paypal_transaction, id: nil)
          unless paypal_transaction.is_a?(::PayPal::SDK::Merchant::DataTypes::GetTransactionDetailsResponseType)
            raise Exception, "#{ self.class.name } must be initialized with a PayPal Transaction" 
          end

          extract_and_store(paypal_transaction)
        end

        def extract_and_store(paypal_transaction)
          @raw_transaction = paypal_transaction

          @id = id || paypal_transaction.payment_transaction_details.payment_info.transaction_id
          @correlation_id = paypal_transaction.correlation_id
          @timestamp = paypal_transaction.timestamp.to_time

          @transaction_type = paypal_transaction.payment_transaction_details.payment_info.transaction_type.to_s
          @payment_type = paypal_transaction.payment_transaction_details.payment_info.payment_type.to_s
          @payment_status = paypal_transaction.payment_transaction_details.payment_info.payment_status.to_s
          @pending_reason = paypal_transaction.payment_transaction_details.payment_info.pending_reason.to_s
          @parent_transaction_id = paypal_transaction.payment_transaction_details.payment_info.parent_transaction_id.to_s
          @payment_date = paypal_transaction.payment_transaction_details.payment_info.payment_date.to_time

          paypal_gross_amount = paypal_transaction.payment_transaction_details.payment_info.gross_amount
          @gross_amount = convert_to_money(amount: paypal_gross_amount.value, currency: paypal_gross_amount.currencyID)

          paypal_fee_amount = paypal_transaction.payment_transaction_details.payment_info.fee_amount
          @fee_amount = convert_to_money(amount: paypal_fee_amount.value, currency: paypal_fee_amount.currencyID)

          paypal_tax_amount = paypal_transaction.payment_transaction_details.payment_info.tax_amount
          @tax_amount = convert_to_money(amount: paypal_tax_amount.value, currency: paypal_tax_amount.currencyID)

          payment_item_amount = paypal_transaction.payment_transaction_details.payment_item_info.payment_item.first.amount
          @payment_item_amount = convert_to_money(amount: payment_item_amount.value, currency: payment_item_amount.currencyID)
        end

        def pending?
          @payment_status == "Pending"
        end

        def complete?
          @payment_status == "Completed"
        end

        def inspect
          to_str
        end

        def to_s
          to_str
        end

        def to_str
          if pending?
            "<#{ self.class.name } type=#{ @transaction_type } payment_type=#{ @payment_type } payment_status=#{ @payment_status } [#{ @pending_reason }] id=#{ @id }>"
          else
            "<#{ self.class.name } type=#{ @transaction_type } payment_type=#{ @payment_type } payment_status=#{ @payment_status } id=#{ @id }>"
          end
        end
        
        class << self
          def find(id)
            paypal_transaction = find_raw(id)

            if paypal_transaction
              new(paypal_transaction, id: id)
            else
              nil
            end
          end

          def find_raw(id)
            api = ::PaymentRecipes::PayPal::SOAP::Settings.api

            begin
              get_transaction_details = api.build_get_transaction_details({
                :TransactionID => id })

              response = api.get_transaction_details(get_transaction_details)

              response

            rescue Exception
              nil
            end
          end
        end
      end
    end
  end
end