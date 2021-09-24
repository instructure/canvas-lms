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

module QtiExporter
  class Engine < Rails::Engine
    config.paths['lib'].eager_load!

    config.to_prepare do
      python_converter_found = Qti.migration_executable ? true : false

      Canvas::Plugin.register :qti_converter, :export_system, {
              :name => proc { I18n.t(:qti_name, 'QTI Converter') },
              :display_name => proc { I18n.t(:qti_display, 'QTI') },
              :author => 'Instructure',
              :description => 'This enables converting QTI .zip files to Canvas quiz json.',
              :version => '1.0.0',
              :settings_partial => 'plugins/qti_converter_settings',
              :select_text => proc { I18n.t(:qti_file_description, 'QTI .zip file') },
              :settings => {
                :enabled => python_converter_found,
                :migration_partial => 'qti_config',
                :worker=> 'QtiWorker',
                :requires_file_upload => true,
                :provides =>{:qti=>Qti::Converter,
                             :webct=>Qti::Converter, # It can import WebCT Quizzes
                },
                :valid_contexts => %w{Account Course}
              },
              :validator => 'QtiPluginValidator'
      }
    end
  end
end
