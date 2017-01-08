module PaymentRecipes
  module PayPal
    class Sale
      attr_reader :currency
      attr_reader :total
      attr_reader :create_time
      attr_reader :id
      attr_reader :payment
      attr_reader :payment_id
      attr_reader :state
      attr_reader :update_time

      attr_reader :transaction_fee
      attr_reader :payment_mode
      attr_reader :protection_eligibility
      attr_reader :protection_eligibility_type

      attr_reader :expanded
      attr_reader :raw_sale

      include ::PaymentRecipes::Utils::Converters
      include ::PaymentRecipes::Utils::Equality

      def initialize(paypal_sale, payment: nil, expanded: false)
        unless paypal_sale.is_a?(::PayPal::SDK::REST::DataTypes::Sale)
          raise Exception, "#{ self.class.name } must be initialized with a PayPal Sale" 
        end

        if payment
          unless payment.is_a?(::PaymentRecipes::PayPal::Payment)
            raise Exception, "Parameter payment must be a PaymentRecipes::PayPal::Payment"
          end

          @payment = payment
          @payment_id = payment.id
        end

        extract_and_store(paypal_sale)
        @expanded = expanded
      end

      def reload!
        paypal_sale = self.class.find_raw(@id)
        extract_and_store(paypal_sale)
        @expanded = true

        self
      end

      def reload_payment!
        @payment = ::PaymentRecipes::PayPal::Payment.find(@payment_id) 

        @payment
      end

      def payment
        reload_payment! unless @payment

        @payment
      end

      def transaction_fee
        reload! unless @transaction_fee

        @transaction_fee
      end

      def payment_mode
        reload! unless @payment_mode

        @payment_mode
      end

      def protection_eligibility
        reload! unless @protection_eligibility

        @protection_eligibility
      end

      def protection_eligibility_type
        reload! unless @protection_eligibility_type

        @protection_eligibility_type
      end

      def refunds
        payment.refunds.select do |refund|
          refund.sale_id == @id
        end
      end

      def refund
        refunds.first
      end

      def inspect
        to_str
      end

      def to_s
        to_str
      end

      def to_str
        "<#{ self.class.name } total=#{ @total.format } state=#{ @state } id=#{ @id }>"
      end

      def can_be_refunded?
        completed?
      end

      def completed?
        @state == :completed
      end

      def partially_refunded?
        @state == :partially_refunded
      end

      def pending?
        @state == :pending
      end

      def refunded?
        @state == :refunded
      end

      def denied?
        @state == :denied
      end

      class << self
        def find(id)
          paypal_sale = find_raw(id)

          if paypal_sale
            new(paypal_sale, payment: nil, expanded: true)
          else
            nil
          end
        end

        def find_raw(id)
          begin
            ::PayPal::SDK::REST::Sale.find(id)

          rescue ::PayPal::SDK::Core::Exceptions::ResourceNotFound
            nil
          end
        end
      end

      def extract_and_store(paypal_sale)
        @currency                     = convert_to_string(paypal_sale.amount.currency)
        @total                        = convert_to_money(amount: paypal_sale.amount.total, currency: @currency)
        @create_time                  = convert_to_time(paypal_sale.create_time)
        @update_time                  = convert_to_time(paypal_sale.update_time)
        @id                           = convert_to_string(paypal_sale.id)
        @payment_id                   = convert_to_string(paypal_sale.parent_payment)
        @state                        = convert_to_symbol(paypal_sale.state)
        @raw_sale                     = paypal_sale

        @transaction_fee              = convert_to_money(amount: paypal_sale.transaction_fee.value, currency: paypal_sale.transaction_fee.currency)
        @payment_mode                 = convert_to_string(paypal_sale.payment_mode)
        @protection_eligibility       = convert_to_string(paypal_sale.protection_eligibility)
        @protection_eligibility_type  = convert_to_string(paypal_sale.protection_eligibility_type)
      end
    end
  end
end