class Dhl::Tracking
  class InputError < StandardError
    def log_level; :verbose; end # by default we won't log these
  end
  class OptionsError < InputError; end
  class IwbNumberNotSetError < InputError; end

  class Upstream < StandardError
    def log_level; :critical; end # by default we will log these
    class UnknownError < Upstream; end
    class ValidationFailureError < Upstream; end
    class ParsinDataError < Upstream; end
    class ConditionError < Upstream
      attr_reader :code, :message
      def initialize(code, message)
        @code = code
        @message = message
      end

      def to_s
        "#{code}: #{message}"
      end
    end
  end
end
