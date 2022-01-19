# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class Account::SettingsWrapper
  def initialize(account, hash)
    @account = account
    @hash = hash
  end

  delegate :[], :[]=, :delete, :reject!, :key?, :has_key?, to: :@hash
  # TODO: eventually drop this set, since they all break through the facade this wrapper is providing
  delegate :merge, :merge!, :to_h, :as_json, to: :@hash

  def dig(base, *keys)
    keys.length.positive? ? self[base]&.dig(*keys) : self[base]
  end

  def fetch(key, default_value = nil)
    res = self[key]
    return res unless res.nil?

    if block_given?
      yield
    else
      default_value
    end
  end
end
