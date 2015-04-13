$LOAD_PATH << File.dirname(__FILE__)

require 'rubocop'
require 'rubocop_canvas/version'

require 'rubocop_canvas/helpers/migration_tags'
require 'rubocop_canvas/helpers/comments'
require 'rubocop_canvas/helpers/diff_parser'

require 'rubocop_canvas/cops/lint/freeze_constants'
require 'rubocop_canvas/cops/rails/smart_time_zone'
require 'rubocop_canvas/cops/datafixup/find_ids'
require 'rubocop_canvas/cops/migration/concurrent_index'
require 'rubocop_canvas/cops/migration/primary_key'
require 'rubocop_canvas/cops/migration/remove_column'
require 'rubocop_canvas/cops/migration/send_later'

module RuboCop
  module Canvas
    module Inject
      DEFAULT_FILE = File.expand_path("../../config/default.yml", __FILE__)

      def self.defaults!
        hash = YAML.load_file(DEFAULT_FILE)
        config = ConfigLoader.merge_with_default(hash, DEFAULT_FILE)

        ConfigLoader.instance_variable_set(:@default_configuration, config)
      end
    end
  end
end

RuboCop::Canvas::Inject.defaults!
