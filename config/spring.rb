# frozen_string_literal: true

module Spring
  module Commands
    class FlakeySpecCatcher
      def env(*)
        'test'
      end
    end

    Spring.register_command 'flakey_spec_catcher', FlakeySpecCatcher.new
  end
end
