module PaymentRecipes
  module PayPal
    module SOAP
      class Settings
      	def self.configure(live: false, app_id:, username:, password:, signature:)
          mode = live ? "live" : "sandbox"

          ::PayPal::SDK.configure(
            :mode      => mode,
            :app_id    => app_id,
            :username  => username,
            :password  => password,
            :signature => signature )
        end

        def self.api
          ::PayPal::SDK::Merchant.new
        end
      end
    end
  end
end