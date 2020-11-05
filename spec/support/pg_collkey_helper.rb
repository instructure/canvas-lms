# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module PGCollkeyHelper
  def pg_collkey_enabled?
    return @pg_collkey_enabled if defined?(@pg_collkey_enabled)
    @pg_collkey_enabled = begin
      status = if ActiveRecord::Base.connection.extension_installed?(:pg_collkey)
        begin
          Bundler.require 'icu'
          true
        rescue LoadError
          skip 'requires pg_collkey for icu to work' # rubocop:disable Specs/NoSkipWithoutTicket
          false
        end
      end

      status || false
    end
  end

  def skip_unless_pg_collkey_present
    skip "requires pg_collkey" unless pg_collkey_enabled?
  end
end
