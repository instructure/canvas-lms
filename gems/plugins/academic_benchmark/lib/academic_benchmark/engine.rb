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

module AcademicBenchmark
  class Engine < ::Rails::Engine
    config.paths['lib'].eager_load!

    config.to_prepare do
      Canvas::Plugin.register :academic_benchmark_importer, :export_system, {
              :name => proc { I18n.t(:name, 'Academic Benchmark Importer') },
              :author => 'Instructure',
              :description => proc { t(:description, 'This enables importing Academic Benchmark standards into Canvas.') },
              :version => AcademicBenchmark::VERSION,
              :settings_partial => 'academic_benchmark/plugin_settings',
              :hide_from_users => true,
              :settings => {
                :common_core_guid => AcademicBenchmark::Converter::COMMON_CORE_GUID,
                :partner_id => nil,
                :partner_key => nil,
                :worker => 'CCWorker',
                :converter_class => AcademicBenchmark::Converter,
                :provides => {:academic_benchmark => AcademicBenchmark::Converter},
                :valid_contexts => %w{Account}
              }
      }
    end
  end
end
