module BasicLTI
  module VariableSubstitution
    class AbstractSubstitutor
      attr_accessor :launch
      def initialize(launch)
        self.launch = launch
      end

      def root_account
        launch.root_account
      end

      def user
        launch.user
      end

      def assignment
        launch.assignment
      end

      def context
        launch.context
      end

      def pseudonym
        launch.pseudonym
      end
    end
  end
end
