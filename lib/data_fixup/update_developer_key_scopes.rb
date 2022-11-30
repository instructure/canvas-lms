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

module DataFixup
  module UpdateDeveloperKeyScopes
    def self.create_scope_query(old_route)
      DeveloperKey.where("scopes LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(old_route)}%")
    end

    def self.run(start_at, end_at, scope_changes)
      return unless scope_changes.any?

      or_conditions = scope_changes.keys.map { |old_scope| create_scope_query(old_scope) }.inject(&:or)

      DeveloperKey.where(id: start_at..end_at).and(or_conditions).find_in_batches do |dk_batch|
        dk_batch.each do |dk|
          dk.scopes = dk.scopes.map { |scope| scope_changes[scope] || scope }.reject { |scope| scope == "DELETED" }
          begin
            dk.save!
          rescue ActiveRecord::RecordInvalid => e
            Rails.logger.info("Developer #{dk.global_id} key scope fixup threw #{e}")
          end
        end
      end
    end
  end
end
