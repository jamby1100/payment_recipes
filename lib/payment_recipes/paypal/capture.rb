module PaymentRecipes
  module PayPal
    class Capture
      attr_reader :currency
      attr_reader :total
      attr_reader :create_time
      attr_reader :id
      attr_reader :payment
      attr_reader :payment_id
      attr_reader :state
      attr_reader :update_time
      attr_reader :transaction_fee
      attr_reader :raw_capture

      include ::PaymentRecipes::Utils::Converters
      include ::PaymentRecipes::Utils::Equality

      def initialize(paypal_capture, payment: nil)
        unless paypal_capture.is_a?(::PayPal::SDK::REST::DataTypes::Capture)
          raise Exception, "#{ self.class.name } must be initialized with a PayPal Capture" 
        end

        if payment
          unless payment.is_a?(::PaymentRecipes::PayPal::Payment)
            raise Exception, "Parameter payment must be a PaymentRecipes::PayPal::Payment"
          end

          @payment = payment
          @payment_id = payment.id
        end

        extract_and_store(paypal_capture)
      end

      def reload!
        paypal_capture = self.class.find_raw(@id)
        extract_and_store(paypal_capture)

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

      def authorizations
        payment.authorizations
      end

      def authorization
        payment.authorization
      end

      def refunds
        payment.refunds.select do |refund|
          refund.capture_id == @id
        end
      end

      def refund
        refunds.first
      end

      def can_be_refunded?
        completed?
      end

      def pending?
        @state == :pending
      end

      def completed?
        @state == :completed
      end

      def refunded?
        @state = :refunded
      end

      def partially_refunded?
        @state = :partially_refunded
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

      class << self
        def find(id)
          paypal_capture = find_raw(id)

          if paypal_capture
            new(paypal_capture, payment: nil)
          else
            nil
          end
        end

        def find_raw(id)
          begin
            ::PayPal::SDK::REST::Capture.find(id)

          rescue ::PayPal::SDK::Core::Exceptions::ResourceNotFound
            nil
          end
        end
      end

      def extract_and_store(paypal_capture)
        @currency                     = convert_to_string(paypal_capture.amount.currency)
        @total                        = convert_to_money(amount: paypal_capture.amount.total, currency: @currency)
        @create_time                  = convert_to_time(paypal_capture.create_time)
        @update_time                  = convert_to_time(paypal_capture.update_time)
        @id                           = convert_to_string(paypal_capture.id)
        @payment_id                   = convert_to_string(paypal_capture.parent_payment)
        @state                        = convert_to_symbol(paypal_capture.state)
        @transaction_fee              = convert_to_money(amount: paypal_capture.transaction_fee.value, currency: paypal_capture.transaction_fee.currency)
        @raw_capture                  = paypal_capture
      end
    end
  end
end