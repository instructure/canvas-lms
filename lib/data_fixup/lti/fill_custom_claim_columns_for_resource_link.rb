# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DataFixup::Lti::FillCustomClaimColumnsForResourceLink
  def self.run
    update_context!
    drop_resource_links_without_a_context

    Lti::ResourceLink.in_batches do |resource_links|
      update_lookup_id!(resource_links)
    end
  end

  def self.drop_resource_links_without_a_context
    Lti::LineItem.connection.execute(%{
      DELETE FROM #{Lti::LineItem.quoted_table_name}
      WHERE lti_resource_link_id IN (
        SELECT ID FROM #{Lti::ResourceLink.quoted_table_name}
        WHERE context_type IS NULL OR context_id IS NULL
      );
    })

    Lti::ResourceLink.connection.execute(%{
      DELETE FROM #{Lti::ResourceLink.quoted_table_name}
      WHERE context_type IS NULL OR context_id IS NULL;
    })
  end

  def self.update_context!
    Lti::ResourceLink.
      joins("INNER JOIN #{Assignment.quoted_table_name} ON assignments.lti_context_id = lti_resource_links.resource_link_id").
      update_all("context_type = 'Assignment', context_id = assignments.id")
  end

  def self.update_lookup_id!(resource_links)
    resource_links.each do |resource_link|
      resource_link.update!(lookup_id: SecureRandom.uuid)
    end
  end
end
