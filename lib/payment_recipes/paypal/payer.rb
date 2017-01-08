module PaymentRecipes
  module PayPal
    class Payer
      attr_reader :payment_method
      attr_reader :funding_instruments
      attr_reader :raw_payer

      include ::PaymentRecipes::Utils::Converters

      def initialize(paypal_payer)
        unless paypal_payer.is_a?(::PayPal::SDK::REST::DataTypes::Payer)
          raise Exception, "#{ self.class.name } must be initialized with a PayPal Payer" 
        end

        @payment_method = convert_to_symbol(paypal_payer.payment_method)
        @raw_payer      = paypal_payer
      end

      def funding_instrument
        @funding_instruments.first
      end

      def inspect
        to_str
      end

      def to_s
        to_str
      end

      def to_str
        "<#{ self.class.name } payment_method=#{ @payment_method }>"
      end
    end
  end
end