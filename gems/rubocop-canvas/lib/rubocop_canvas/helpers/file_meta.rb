module RuboCop
  module Cop
    module FileMeta
      def file_name
        processed_source.buffer.name.split('/').last
      end
    end
  end
end
