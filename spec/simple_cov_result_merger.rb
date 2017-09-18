#
# Copyright (C) 2017 - present Instructure, Inc.
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

require "simplecov"
require "simplecov-rcov"

class SimpleCov::Formatter::MergedFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result)
    SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end

SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
SimpleCov.add_filter '/spec/'
SimpleCov.add_filter '/config/'
SimpleCov.add_filter '/db_imports/'
SimpleCov.add_filter '/distributed_ci/'
SimpleCov.add_filter '/spec_canvas/'
SimpleCov.add_filter '/db/'
SimpleCov.add_filter %r{^_cache/} # https://github.com/colszowka/simplecov/pull/617

SimpleCov.add_group 'Controllers', 'app/controllers'
SimpleCov.add_group 'Models', 'app/models'
SimpleCov.add_group 'Services', 'app/services'
SimpleCov.add_group 'App', 'app/'
SimpleCov.add_group 'Gems', 'gems/'
SimpleCov.add_group 'Helpers', 'app/helpers'
SimpleCov.add_group 'Libraries', 'lib/'
SimpleCov.add_group 'Plugins', 'vendor/plugins'

SimpleCov.add_group "Long files" do |src_file|
  src_file.lines.count > 500
end

SimpleCov.result.format!
