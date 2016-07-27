$LOAD_PATH << File.dirname(__FILE__)

require 'rubocop'
require 'rubocop_canvas/version'

# helpers
require 'rubocop_canvas/helpers/comments'
require 'rubocop_canvas/helpers/consts'
require 'rubocop_canvas/helpers/diff_parser'
require 'rubocop_canvas/helpers/file_meta'
require 'rubocop_canvas/helpers/file_sieve'
require 'rubocop_canvas/helpers/git_proxy'
require 'rubocop_canvas/helpers/migration_tags'

# cops
## datafixup
require 'rubocop_canvas/cops/datafixup/eager_load'
## lint
require 'rubocop_canvas/cops/lint/freeze_constants'
require 'rubocop_canvas/cops/lint/no_file_utils_rm_rf'
require 'rubocop_canvas/cops/lint/no_sleep'
## migration
require 'rubocop_canvas/cops/migration/concurrent_index'
require 'rubocop_canvas/cops/migration/model_behavior'
require 'rubocop_canvas/cops/migration/primary_key'
require 'rubocop_canvas/cops/migration/remove_column'
require 'rubocop_canvas/cops/migration/send_later'
## rails
require 'rubocop_canvas/cops/rails/smart_time_zone'
## specs
require 'rubocop_canvas/cops/specs/no_before_all'
require 'rubocop_canvas/cops/specs/no_before_once_stubs'
require 'rubocop_canvas/cops/specs/ensure_spec_extension'
require 'rubocop_canvas/cops/specs/no_execute_script'
require 'rubocop_canvas/cops/specs/prefer_f_over_fj'
require 'rubocop_canvas/cops/specs/scope_helper_modules'

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
