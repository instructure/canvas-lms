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

require "i18nliner/scope"

class I18nliner::Scope
  ABSOLUTE_KEY = /\A#/

  def normalize_key(key, inferred_key, explicit_scope_option)
    return nil if key.nil?

    key = key.to_s
    key = key.dup if key.frozen?
    return key if key.sub!(ABSOLUTE_KEY, "") || !scope || inferred_key || explicit_scope_option

    scope + key
  end
end
