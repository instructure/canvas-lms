#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

$LOAD_PATH << File.dirname(__FILE__)

require 'rubocop'
require 'rubocop_canvas/version'

# helpers
require 'rubocop_canvas/helpers/consts'
require 'rubocop_canvas/helpers/file_meta'
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
require 'rubocop_canvas/cops/specs/no_disable_implicit_wait.rb'
require 'rubocop_canvas/cops/specs/ensure_spec_extension'
require 'rubocop_canvas/cops/specs/no_execute_script'
require 'rubocop_canvas/cops/specs/no_no_such_element_error'
require 'rubocop_canvas/cops/specs/no_selenium_web_driver_wait.rb'
require 'rubocop_canvas/cops/specs/no_skip_without_ticket'
require 'rubocop_canvas/cops/specs/no_strftime'
require 'rubocop_canvas/cops/specs/no_wait_for_no_such_element'
require 'rubocop_canvas/cops/specs/prefer_f_over_fj'
require 'rubocop_canvas/cops/specs/scope_helper_modules'
require 'rubocop_canvas/cops/specs/deterministic_described_classes'
require 'rubocop_canvas/cops/specs/scope_includes'

module RuboCop
  module Canvas
    module Inject
      DEFAULT_FILE = File.expand_path("../../config/default.yml", __FILE__)

      def self.defaults!
        path = File.absolute_path(DEFAULT_FILE)
        hash = ConfigLoader.send(:load_yaml_configuration, path)
        config = Config.new(hash, path)
        config = ConfigLoader.merge_with_default(config, path)

        ConfigLoader.instance_variable_set(:@default_configuration, config)
      end
    end
  end
end

RuboCop::Canvas::Inject.defaults!
