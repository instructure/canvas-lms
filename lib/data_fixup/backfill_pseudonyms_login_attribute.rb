# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
  module BackfillPseudonymsLoginAttribute
    def self.run(auth_types)
      Pseudonym.find_ids_in_ranges(loose: true, batch_size: 5_000) do |min_id, max_id|
        # the combination of a join, a limit, and assigning from another table is too complicated
        # for our AR extensions, so form the subquery ourselves
        Pseudonym.joins(:authentication_provider)
                 .where(id: min_id..max_id, login_attribute: nil, authentication_providers: { auth_type: auth_types })
                 .where.not(authentication_providers: { login_attribute: nil })
                 .where.not(Pseudonym.from("#{Pseudonym.quoted_table_name} p2")
                            .where(<<~SQL.squish)
                              pseudonyms.authentication_provider_id=p2.authentication_provider_id AND
                              LOWER(pseudonyms.unique_id)=LOWER(p2.unique_id) AND
                              authentication_providers.login_attribute=p2.login_attribute
                            SQL
                            .arel.exists)
                 .update_all("login_attribute=authentication_providers.login_attribute")
      end
    end
  end
end
