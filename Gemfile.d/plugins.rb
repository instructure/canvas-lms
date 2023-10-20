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

inline_plugins = %w[
  academic_benchmark
  account_reports
  moodle_importer
  qti_exporter
  respondus_soap_endpoint
  simply_versioned
].freeze

gemfile_root.glob("../gems/plugins/*") do |plugin_dir|
  next unless File.directory?(plugin_dir)

  gem_name = File.basename(plugin_dir)
  next unless @include_plugins || inline_plugins.include?(gem_name)

  gem(gem_name, path: plugin_dir.relative_path_from(gemfile_root))
end
