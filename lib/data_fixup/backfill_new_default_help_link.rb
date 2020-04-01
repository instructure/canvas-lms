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
  module BackfillNewDefaultHelpLink
    def self.run(help_link_id)
      help_link_id = help_link_id.to_sym

      Account.root_accounts.active.non_shadow.find_each do |account|
        next unless account.settings[:custom_help_links]
        link_config = account.help_links_builder.default_links(false).find { |hl| hl[:id] == help_link_id }
        next unless link_config
        next if account.settings[:custom_help_links].any? { |hl| hl.with_indifferent_access[:id]&.to_sym == help_link_id }
        account.settings[:custom_help_links] += account.help_links_builder.instantiate_links([link_config])
        account.save!
      end
    end
  end
end
