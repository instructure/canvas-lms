module RuboCop
  module Cop
    module FileMeta
      SPEC_FILE_NAME_REGEX = /_spec\.rb$/
      CONTROLLER_FILE_NAME_REGEX = /controller\.rb$/

      def file_name
        file_path.split('/').last
      end

      def file_path
        processed_source.buffer.name
      end

      def named_as_spec?
        file_name =~ SPEC_FILE_NAME_REGEX
      end

      def named_as_controller?
        file_name =~ CONTROLLER_FILE_NAME_REGEX
      end
    end
  end
end
