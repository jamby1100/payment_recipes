module PaymentRecipes
  module PayPal
    module Action
      class RefundCapture < PaymentRecipes::Utils::Action
        variable :capture, PaymentRecipes::PayPal::Capture

        def perform
          if @capture.can_be_refunded?
            @capture.raw_capture.refund({})

            @capture.reload!
            @capture.reload_payment!
          else
            raise Exception, "Capture can't be refunded"
          end

          @capture
        end
      end
    end
  end
end