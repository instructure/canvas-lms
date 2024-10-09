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

module DataFixup
  module DeleteHelpLinks
    def self.run(help_link_id)
      help_link_id = help_link_id.to_sym

      Account.root_accounts.active.non_shadow.find_each do |account|
        next unless account.primary_settings_root_account?

        links = account.settings[:custom_help_links]
        next unless links

        links.delete_if { |l| l[:id] == help_link_id }

        account.settings[:custom_help_links] = links
        account.save!
      end
    end
  end
end
