module PaymentRecipes
  module PayPal
    module REST
      class Refund
        attr_reader :id
        attr_reader :currency
        attr_reader :total
        attr_reader :payment
        attr_reader :payment_id
        attr_reader :state  
        
        attr_reader :create_time 
        attr_reader :update_time  

        attr_reader :sale_id 
        attr_reader :sale

        attr_reader :capture_id  
        attr_reader :capture

        attr_reader :raw_refund 

        include ::PaymentRecipes::Utils::Converters
        include ::PaymentRecipes::Utils::Equality

        def initialize(paypal_refund, payment: nil)
          unless paypal_refund.is_a?(::PayPal::SDK::REST::DataTypes::Refund)
            raise Exception, "#{ self.class.name } must be initialized with a PayPal Refund"
          end

          if payment
            unless payment.is_a?(::PaymentRecipes::PayPal::REST::Payment)
              raise Exception, "Parameter payment must be a PaymentRecipes::PayPal::Payment"
            end

            @payment = payment
            @payment_id = payment.id
          end

          extract_and_store(paypal_refund)
        end

        def reload!
          paypal_refund = self.class.find_raw(@id)
          extract_and_store(paypal_refund)

          self
        end

        def reload_payment!
          @payment = ::PaymentRecipes::PayPal::REST::Payment.find(@payment_id) 

          @payment
        end

        def reload_sale!
          return unless @sale_id

          @sale = ::PaymentRecipes::PayPal::REST::Sale.find(@sale_id)

          @sale
        end

        def reload_capture!
          return unless @capture_id

          @capture = ::PaymentRecipes::PayPal::REST::Capture.find(@capture_id)

          @capture
        end

        def payment
          reload_payment! unless @payment

          @payment
        end

        def capture
          reload_capture! unless @capture

          @capture
        end

        def sale
          reload_sale! unless @sale

          @sale
        end

        def authorizations
          payment.authorizations
        end

        def authorization
          payment.authorization
        end

        def pending?
          @state == :pending
        end

        def completed?
          @state == :completed
        end

        def failed?
          @state == :failed
        end

        def inspect
          to_str
        end

        def to_s
          to_str
        end

        def to_str
          "<#{ self.class.name } total=#{ @total.format } state=#{ @state } id=#{ @id }>"
        end

        class << self
          def find(id)
            paypal_refund = find_raw(id)

            if paypal_refund
              new(paypal_refund, payment: nil)
            else
              nil
            end
          end

          def find_raw(id)
            begin
              ::PayPal::SDK::REST::Refund.find(id)

            rescue ::PayPal::SDK::Core::Exceptions::ResourceNotFound
              nil
            end
          end
        end

        def extract_and_store(paypal_refund)
          @id               = convert_to_string(paypal_refund.id)
          @currency         = convert_to_string(paypal_refund.amount.currency)
          @total            = convert_to_money(amount: paypal_refund.amount.total, currency: paypal_refund.amount.currency)
          @payment_id       = convert_to_string(paypal_refund.parent_payment)
          @state            = convert_to_symbol(paypal_refund.state)
          
          @create_time      = convert_to_time(paypal_refund.create_time)
          @update_time      = convert_to_time(paypal_refund.update_time)

          @sale_id          = convert_to_string(paypal_refund.sale_id)
          @capture_id       = convert_to_string(paypal_refund.capture_id)
          @raw_refund       = paypal_refund
        end
      end
    end
  end
end