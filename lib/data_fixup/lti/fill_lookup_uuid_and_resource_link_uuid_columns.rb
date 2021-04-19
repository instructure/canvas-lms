# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module DataFixup::Lti::FillLookupUuidAndResourceLinkUuidColumns
  def self.run
    resource_links_to_update.in_batches do |resource_links|
      update_columns!(resource_links)
    end
  end

  # Our assumption is if the data-type is not valid anymore, it was due to an
  # accidental action (e.g. some change using rails console).
  # Canvas is responsible for generating the UUID and uses rails before actions
  # as Lti::ResourceLink.generate_lookup_id/generate_resource_link_id to set
  # the UUID properly.
  #
  # We figure out that we could:
  #  1. drop the record with invalid UUID, or;
  #  2. set a new UUID value to the columns that have invalid value;
  #
  # So, we decide that will be better to follow the second approach by
  # re-generate the UUID and set it to the old and the new column for consistency.
  def self.update_columns!(resource_links)
    resource_links.each do |resource_link|
      options = {
        lookup_uuid: resource_link.lookup_id,
        resource_link_uuid: resource_link.resource_link_id
      }

      unless UuidHelper.valid_format?(resource_link.lookup_id)
        Rails.logger.info("[#{name}] generating a new lookup_id for id: #{resource_link.id}, lookup_id: #{resource_link.lookup_id}")
        options[:lookup_id] = options[:lookup_uuid] = SecureRandom.uuid
      end

      unless UuidHelper.valid_format?(resource_link.resource_link_id)
        Rails.logger.info("[#{name}] generating a new resource_link_id for id: #{resource_link.id}, resource_link_id: #{resource_link.resource_link_id}")
        options[:resource_link_id] = options[:resource_link_uuid] = SecureRandom.uuid
      end

      resource_link.update!(options)
    end
  end

  def self.resource_links_to_update
    Lti::ResourceLink.where(lookup_uuid: nil).or(Lti::ResourceLink.where(resource_link_uuid: nil))
  end
end
