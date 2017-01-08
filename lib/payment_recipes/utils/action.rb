module PaymentRecipes
  module Utils
    class Action
      class << self
        def variable(key, klass)
          @rules ||= {}
          @rules[key] = klass

          define_method key do
            instance_variable_get("@#{ key }".to_sym)
          end
        end

        def rules
          @rules
        end

        def prepare(parameters)
          @rules.each do |key, klass|
            unless parameters[key].is_a?(klass)
              raise Exception, "#{ key } should be a #{ klass }"
            end
          end

          new(parameters)
        end
      end

      def initialize(parameters)
        raise Exception, "Action params should be a Hash" unless parameters.is_a?(Hash)

        @params = parameters
        @params.each do |param, value|
          instance_variable_set("@#{ param }".to_sym, value)
        end
      end
    end
  end
end