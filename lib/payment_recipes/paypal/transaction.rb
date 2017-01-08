module PaymentRecipes
  module PayPal
    class Transaction
      attr_reader :currency
      attr_reader :total
      attr_reader :payment
      attr_reader :payment_id
      attr_reader :description

      attr_reader :subtotal
      attr_reader :tax
      attr_reader :fee
      attr_reader :shipping
      attr_reader :handling_fee
      attr_reader :insurance
      attr_reader :shipping_discount
      attr_reader :insurance
      attr_reader :gift_wrap

      attr_reader :sales
      attr_reader :authorizations
      attr_reader :captures
      attr_reader :refunds

      attr_reader :raw_transaction

      include ::PaymentRecipes::Utils::Converters

      def initialize(paypal_transaction, payment:, expand: false)
        unless paypal_transaction.is_a?(::PayPal::SDK::REST::DataTypes::Transaction)
          raise Exception, "#{ self.class.name } must be initialized with a PayPal Transaction" 
        end

        unless payment.is_a?(::PaymentRecipes::PayPal::Payment)
          raise Exception, "Parameter payment must be a PaymentRecipes::PayPal::Payment"
        end

        @currency           = convert_to_string(paypal_transaction.amount.currency)
        @total              = convert_to_money(amount: paypal_transaction.amount.total, currency: @currency)
        @description        = convert_to_string(paypal_transaction.description)
        @payment            = payment
        @payment_id         = payment.id

        @subtotal           = convert_to_money(amount: paypal_transaction.amount.details.subtotal, currency: @currency)
        @tax                = convert_to_money(amount: paypal_transaction.amount.details.tax, currency: @currency)
        @fee                = convert_to_money(amount: paypal_transaction.amount.details.fee, currency: @currency)
        @shipping           = convert_to_money(amount: paypal_transaction.amount.details.shipping, currency: @currency)
        @handling_fee       = convert_to_money(amount: paypal_transaction.amount.details.handling_fee, currency: @currency)
        @insurance          = convert_to_money(amount: paypal_transaction.amount.details.insurance, currency: @currency)
        @shipping_discount  = convert_to_money(amount: paypal_transaction.amount.details.shipping_discount, currency: @currency)
        @insurance          = convert_to_money(amount: paypal_transaction.amount.details.insurance, currency: @currency)
        @gift_wrap          = convert_to_money(amount: paypal_transaction.amount.details.gift_wrap, currency: @currency)
        @raw_transaction    = paypal_transaction

        @sales              = []
        @authorizations     = []
        @captures           = []
        @refunds            = []

        paypal_transaction.related_resources.each do |paypal_related_resource|
          if paypal_related_resource.sale.id 
            sale = ::PaymentRecipes::PayPal::Sale.new(paypal_related_resource.sale, payment: payment)
            sale.reload! if expand

            @sales << sale
          end

          if paypal_related_resource.authorization.id
            authorization = ::PaymentRecipes::PayPal::Authorization.new(paypal_related_resource.authorization, payment: payment)
            authorization.reload! if expand

            @authorizations << authorization
          end

          if paypal_related_resource.capture.id
            capture = ::PaymentRecipes::PayPal::Capture.new(paypal_related_resource.capture, payment: payment)
            @captures << capture
          end

          if paypal_related_resource.refund.id
            refund = ::PaymentRecipes::PayPal::Refund.new(paypal_related_resource.refund, payment: payment)
            @refunds << refund
          end
        end
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
        "<#{ self.class.name } total=#{ @total.format } sales=#{ @sales.size } authorizations=#{ @authorizations.size } captures=#{ @captures.size }>"
      end
    end
  end
end