module PaymentRecipes
  module Utils
    module Equality
      def ==(other)
        @id == other.id && self.class.name == other.class.name
      end
    end
  end
end