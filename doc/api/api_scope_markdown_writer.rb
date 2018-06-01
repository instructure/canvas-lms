#
# Copyright (C) 2018 - present Instructure, Inc.
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
#
class ApiScopeMarkdownWriter
  def initialize(named_scopes)
    @output_file = Rails.root.join("doc", "api", "api_token_scopes.md")
    @named_scopes = named_scopes
  end

  def generate_markdown!
    File.open(@output_file, 'w+') do |f|
      f.write(header)
      f.write("<style>table { width: 100%; }</style>")
      f.write(intro)
      @named_scopes.each do |resource, scopes|
        f.write("\n## #{resource}\n")
        f.write("|Verb|Endpoint|Scope|\n")
        f.write("|---|---|---|\n")
        scopes.each { |s| f.write("|#{s[:verb]}|#{s[:path]}|#{s[:scope].gsub('|', '&#124;')}|\n") }
      end
    end
  end

  private

  def header
    "Api Token Scopes\n==========================\n"\
    "<h3 class='beta'>BETA: This API resource is not finalized, and there could be breaking changes before its final release.</h3>".freeze
  end

  def intro
    'Below is a list of all API token scopes (See [here](/doc/api/file.developer_keys.html)). '\
    'Scopes may also be found beneath their corresponding endpoints in the "resources" documentation pages.'.freeze
  end
end
