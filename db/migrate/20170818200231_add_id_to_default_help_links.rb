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
#

class AddIdToDefaultHelpLinks < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    default_links = Account::HelpLinks.default_links

    Account.root_accounts.active.find_each do |a|
      next unless a.settings[:custom_help_links]

      found_link = false
      new_links = a.settings[:custom_help_links].map do |link|
        next link unless link[:type] == 'default'
        default_link = default_links.find { |l| l[:url] == link[:url] }
        next link unless default_link
        found_link = true
        default_link
      end
      next unless found_link
      a.settings[:custom_help_links] = Account::HelpLinks.instantiate_links(new_links)
      a.save!
    end
  end
end
