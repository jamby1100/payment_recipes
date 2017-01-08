module PaymentRecipes
  module PayPal
    module Settings
      def self.configure(mode:, client_id:, client_secret:)
        ::PayPal::SDK.configure(
          :mode => mode.to_s, # "sandbox" or "live"
          :client_id => client_id,
          :client_secret => client_secret,
          :ssl_options => { } 
        )
      end
    end
  end
end