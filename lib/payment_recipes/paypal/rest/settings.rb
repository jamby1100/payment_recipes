module PaymentRecipes
  module PayPal
    module REST
      module Settings
        def self.configure(live: false, client_id:, client_secret:)
          mode = live ? "live" : "sandbox"

          ::PayPal::SDK.configure(
            :mode => mode,
            :client_id => client_id,
            :client_secret => client_secret,
            :ssl_options => { } 
          )
        end
      end
    end
  end
end