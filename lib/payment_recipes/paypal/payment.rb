module PaymentRecipes
  module PayPal
    class Payment
      attr_reader :id
      attr_reader :intent
      attr_reader :create_time
      attr_reader :update_time
      attr_reader :state
      attr_reader :transactions
      attr_reader :sales
      attr_reader :authorizations
      attr_reader :captures
      attr_reader :refunds
      attr_reader :payer
      attr_reader :raw_payment

      include ::PaymentRecipes::Utils::Converters
      include ::PaymentRecipes::Utils::Equality

      def initialize(paypal_payment, expand: false)
        unless paypal_payment.is_a?(::PayPal::SDK::REST::DataTypes::Payment)
          raise Exception, "#{ self.class.name } must be initialized with a PayPal Payment" 
        end

        extract_and_store(paypal_payment, expand: expand)
      end

      def reload!
        paypal_payment = self.class.find_raw(@id)
        extract_and_store(paypal_payment)

        self
      end

      def transaction
        @transactions.first
      end

      def sale
        @sales.first
      end

      def authorization
        @authorizations.first
      end

      def capture
        @captures.first
      end

      def refund
        @refunds.first
      end

      def inspect
        to_str
      end

      def to_s
        to_str
      end

      def to_str
        "<#{ self.class.name } intent=#{ @intent } state=#{ @state } id=#{ @id }>"
      end

      class << self
        def find(id, expand: false)
          paypal_payment = find_raw(id)

          if paypal_payment
            new(paypal_payment, expand: expand)
          else
            nil
          end
        end

        def find_raw(id)
          begin
            ::PayPal::SDK::REST::Payment.find(id)

          rescue ::PayPal::SDK::Core::Exceptions::ResourceNotFound
            nil
          end
        end

        def history(count:, page: 1, expand: false)
          paypal_payment_history = ::PayPal::SDK::REST::Payment.all(count: count, start_index: count * (page - 1))

          paypal_payment_history.payments.map do |paypal_payment|
            new(paypal_payment, expand: expand)
          end
        end
      end

      private

      def extract_and_store(paypal_payment, expand: false)
        @id               = convert_to_string(paypal_payment.id)
        @intent           = convert_to_symbol(paypal_payment.intent)
        @create_time      = convert_to_time(paypal_payment.create_time)
        @update_time      = convert_to_time(paypal_payment.update_time)
        @state            = convert_to_symbol(paypal_payment.state)
        @raw_payment      = paypal_payment
        @transactions     = []
        @sales            = []
        @authorizations   = []
        @captures         = []
        @refunds          = []
        @payer            = ::PaymentRecipes::PayPal::Payer.new(paypal_payment.payer)

        paypal_payment.transactions.each do |paypal_transaction|
          transaction = ::PaymentRecipes::PayPal::Transaction.new(paypal_transaction, payment: self, expand: expand)
          @sales += transaction.sales
          @authorizations += transaction.authorizations
          @captures += transaction.captures
          @refunds += transaction.refunds

          @transactions << transaction
        end
      end
    end
  end
end