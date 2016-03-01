module RuboCop
  module Cop
    module FileMeta
      def file_name
        file_path.split('/').last
      end

      def file_path
        processed_source.buffer.name
      end
    end
  end
end
