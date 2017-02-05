"""
class SamplePaymentAction < PaymentRecipes::Utils::Action
  variable :x, 'Integer'

  def perform
    if x
      puts x + 1
    end
  end
end

action = SamplePaymentAction.prepare(x: nil)
action.execute
"""

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
          @rules || []
        end

        def prepare(parameters = {})
          rules.each do |key, klass|
            # unless parameters[key].is_a?(klass.constantize)# || parameters[key].is_a?(NilClass)
            allowed_class_strings = parameters[key].class.ancestors.map(&:to_s)
            unless allowed_class_strings.include?(klass) || allowed_class_strings.include?("NilClass")
              raise TypeError, "#{ key } should be a #{ klass }"
            end
          end

          output = new(parameters)
          output.instance_variable_set(:@_action_state, :prepared)

          output
        end

        def debug
          study rules
        end
      end

      def initialize(parameters = {})
        raise TypeError, "Action params should be a Hash" unless parameters.is_a?(Hash)

        @params = parameters
        @params.each do |param, value|
          instance_variable_set("@#{ param }".to_sym, value)
        end
      end

      def success?
        @success
      end

      def failure?
        not success?
      end

      def execute
        @success = nil
        @error = nil

        unless @_action_state
          raise Exception, "Use #{ self.class.name }.prepare to initialize this action"
        end

        unless @_action_state == :executed
          @_action_output = perform

          if @error
            @success = false
          else
            @success = true
          end

          make_instance_variables_available

          @_action_state = :executed
        end

        @_action_output
      end

      def stored_variables
        output = {}

        instance_variables.each do |instance_variable|
          instance_variable_sym = instance_variable.to_s.gsub("@", "").to_sym

          begin
            output[instance_variable_sym] = send(instance_variable_sym)
          rescue Exception => e
            # NOTE: do nothing
          end
        end

        output
      end

      def make_instance_variables_available
        instance_variables.each do |instance_variable|
          define_singleton_method(instance_variable.to_s.gsub("@", "")) do
            instance_variable_get(instance_variable)
          end
        end
      end

      def ensure_presence(variable, default: nil)
        if variable.present?
          yield if block_given?
        else
          default
        end
      end

      """
      memoize(:x) do
        puts 'executed'
        42
      end
      """
      def store(label)
        label_sym = "@#{label}".to_sym

        if stored_value = instance_variable_get(label_sym)
          stored_value
        else
          if block_given?
            computed_value = yield

            instance_variable_set(label_sym, computed_value)

            define_singleton_method(label_sym.to_s.gsub("@", "")) do
              instance_variable_get(label_sym)
            end
          end
        end

        instance_variable_get(label_sym)
      end

      def set(label, value)
        label_sym = "@#{label}".to_sym

        instance_variable_set(label_sym, value)

        define_singleton_method(label_sym.to_s.gsub("@", "")) do
          instance_variable_get(label_sym)
        end

        value
      end

      def get(label)
        label_sym = "@#{label}".to_sym

        instance_variable_get(label_sym)
      end

      def debug
        study @params
      end
    end
  end
end