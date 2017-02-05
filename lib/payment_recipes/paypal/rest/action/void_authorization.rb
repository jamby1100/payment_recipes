module PaymentRecipes
  module PayPal
    module REST
      module Action
        class VoidAuthorization < PaymentRecipes::Utils::Action
          variable :authorization, "PaymentRecipes::PayPal::REST::Authorization"

          def perform
            if @authorization.can_be_captured?
              @authorization.raw_authorization.void()

              @authorization.reload!
              @authorization.reload_payment!
            else
              raise Exception, "Authorization can't be voided"
            end

            @authorization  
          end
        end
      end
    end
  end
end