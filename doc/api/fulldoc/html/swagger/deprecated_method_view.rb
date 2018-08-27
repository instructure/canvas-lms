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

require_relative 'canvas_api/deprecatable'
require 'hash_view'

class DeprecatedMethodView < HashView
  include CanvasAPI::Deprecatable

  attr_reader :description, :effective_date, :notice_date

  def initialize(tag)
    @deprecated_date_key = :NOTICE
    @effective_date_key = :EFFECTIVE
    @tag_declaration_line = tag.text
    @tag_type = "method"
    parse_line(tag.text)
  end

  private

  def parse_line(text)
    description = (text || '').split("\n", 2).second
    @description = description && format(description.strip)
    parse_deprecation_info(text)
  end
end
