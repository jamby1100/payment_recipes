module PaymentRecipes
  module PayPal
    module REST
      module Action
        class RefundSale < PaymentRecipes::Utils::Action
          variable :sale, "PaymentRecipes::PayPal::REST::Sale"

          def perform
            if @sale.can_be_refunded?
              @sale.raw_sale.refund({})

              @sale.reload!
              @sale.reload_payment!
            else
              raise Exception, "Sale can't be refunded"
            end

            @sale
          end
        end
      end
    end
  end
end