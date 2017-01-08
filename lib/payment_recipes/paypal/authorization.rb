module PaymentRecipes
  module PayPal
    class Authorization
      attr_reader :id
      attr_reader :currency
      attr_reader :total
      attr_reader :payment
      attr_reader :payment_id
      attr_reader :subtotal
      attr_reader :state
      attr_reader :create_time
      attr_reader :update_time
      attr_reader :valid_until

      attr_reader :payment_mode
      attr_reader :protection_eligibility
      attr_reader :protection_eligibility_type

      attr_reader :expanded
      attr_reader :raw_authorization

      include PaymentRecipes::Utils::Converters
      include PaymentRecipes::Utils::Equality

      def initialize(paypal_authorization, payment: nil, expanded: false)
        unless paypal_authorization.is_a?(::PayPal::SDK::REST::DataTypes::Authorization)
          raise Exception, "#{ self.class.name } must be initialized with a PayPal Authorization" 
        end

        if payment
          unless payment.is_a?(::PaymentRecipes::PayPal::Payment)
            raise Exception, "Parameter payment must be a PaymentRecipes::PayPal::Payment"
          end

          @payment = payment
          @payment_id = payment.id
        end

        extract_and_store(paypal_authorization)
        @expanded = expanded
      end

      def reload!
        paypal_authorization = self.class.find_raw(@id)
        extract_and_store(paypal_authorization)
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

      def captures
        payment.captures
      end

      def capture
        captures.first
      end

      def inspect
        to_str
      end

      def pending?
        @state == :pending
      end

      def authorized?
        @state == :authorized
      end

      def partially_captured?
        @state == :partially_captured
      end

      def captured?
        @state == :captured
      end

      def expired?
        @state == :expired
      end

      def voided?
        @state == :voided
      end

      def can_be_captured?
        authorized? || partially_captured?
      end

      def to_s
        to_str
      end

      def to_str
        "<#{ self.class.name } total=#{ @total.format } state=#{ @state } id=#{ @id }>"
      end

      class << self
        def find(id)
          paypal_authorization = find_raw(id)

          if paypal_authorization
            new(paypal_authorization, payment: nil, expanded: true)
          else
            nil
          end
        end

        def find_raw(id)
          begin
            ::PayPal::SDK::REST::Authorization.find(id)

          rescue ::PayPal::SDK::Core::Exceptions::ResourceNotFound
            nil
          end
        end
      end

      private

      def extract_and_store(paypal_authorization)
        @id                           = convert_to_string(paypal_authorization.id)
        @currency                     = convert_to_string(paypal_authorization.amount.currency)
        @total                        = convert_to_money(amount: paypal_authorization.amount.total, currency: @currency)
        @subtotal                     = convert_to_money(amount: paypal_authorization.amount.details.subtotal, currency: @currency)
        @create_time                  = convert_to_time(paypal_authorization.create_time)
        @update_time                  = convert_to_time(paypal_authorization.update_time)
        @valid_until                  = convert_to_time(paypal_authorization.valid_until)
        @payment_id                   = convert_to_string(paypal_authorization.parent_payment)
        @state                        = convert_to_symbol(paypal_authorization.state)
        @raw_authorization            = paypal_authorization

        @payment_mode                 = convert_to_string(paypal_authorization.payment_mode)
        @protection_eligibility       = convert_to_string(paypal_authorization.protection_eligibility)
        @protection_eligibility_type  = convert_to_string(paypal_authorization.protection_eligibility_type)
      end
    end
  end
end