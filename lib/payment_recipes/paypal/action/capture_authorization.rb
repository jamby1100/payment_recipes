module PaymentRecipes
  module PayPal
    module Action
      class CaptureAuthorization < PaymentRecipes::Utils::Action
        variable :authorization, ::PaymentRecipes::PayPal::Authorization

        def perform
          if @authorization.can_be_captured?
            currency = @authorization.currency
            total = @authorization.total.to_s

            @authorization.raw_authorization.capture({:amount => { :currency => currency, :total => total } })

            @authorization.reload!
            @authorization.reload_payment!
          else
            raise Exception, "Authorization can't be captured"
          end

          @authorization
        end
      end
    end
  end
end