# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
  module RemoveCovidHelpLink
    def self.run
      Account.root_accounts.active.non_shadow.find_each do |account|
        next unless account.settings[:custom_help_links]

        covid_link = account.settings[:custom_help_links].find { |hl| hl.with_indifferent_access[:id]&.to_sym == :covid }
        next unless covid_link

        was_featured = covid_link.with_indifferent_access[:is_featured]

        account.settings[:custom_help_links] = account.settings[:custom_help_links].reject { |hl| hl.with_indifferent_access[:id]&.to_sym == :covid }

        if was_featured
          guides_link = account.settings[:custom_help_links].find { |hl| hl.with_indifferent_access[:id]&.to_sym == :search_the_canvas_guides }
          guides_link[:is_featured] = true if guides_link
        end

        account.save!
      end
    end
  end
end
