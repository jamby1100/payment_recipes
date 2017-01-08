module PaymentRecipes
  module Utils
    module Converters
      def convert_to_time(target)
        nil_check(target) do
          if defined?(Time.zone)
            Time.zone.parse(target)
          else
            Time.parse(target)
          end
        end
      end

      def convert_to_string(target)
        nil_check(target) do
          target.to_s
        end
      end

      def convert_to_money(amount:, currency:)
        nil_check(amount, currency) do
          raise Exception, "Money amount must be a String" unless amount.is_a?(String)

          ::Money.new(::BigDecimal.new(amount) * 100, currency)
        end
      end

      def convert_to_symbol(target)
        nil_check(target) do
          target.to_sym
        end
      end

      private

      def nil_check(*target)
        if target.any? {|x| x.nil?}
          nil
        else
          yield if block_given?
        end
      end
    end
  end
end