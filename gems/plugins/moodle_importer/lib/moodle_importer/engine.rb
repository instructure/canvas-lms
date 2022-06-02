# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Moodle
  class Railtie < ::Rails::Engine
    isolate_namespace Moodle

    config.paths["lib"].eager_load!

    initializer "moodle_importer.canvas_plugin" do
      require "moodle2cc"
    end

    config.to_prepare do
      Canvas::Plugin.register :moodle_converter, :export_system, {
        name: proc { I18n.t(:m2c_name, "Moodle Importer") },
        author: "Divergent Logic",
        description: "This enables importing Moodle 1.9 and 2.x .zip/.mbz files to Canvas.",
        version: "1.0.0",
        select_text: proc { I18n.t(:m2c_file_description, "Moodle 1.9/2.x") },
        settings: {
          migration_partial: "moodle_config",
          worker: "CCWorker",
          provides: { moodle_1_9: Moodle::Converter, moodle_2: Moodle::Converter },
          valid_contexts: %w[Account Course]
        }
      }
    end
  end
end
