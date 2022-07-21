# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module DataFixup::FixResourceLinksFromCopiedCourses
  def self.resource_links_to_update
    # this is the day before the date of the original commit that added urls to resource links
    ActiveRecord::Base.connection.execute(
      "WITH original_resource_links AS (
        SELECT lti_resource_links.id, lti_resource_links.root_account_id, lti_resource_links.lookup_uuid, lti_resource_links.url,
               ROW_NUMBER() OVER(PARTITION BY lti_resource_links.lookup_uuid
                                     ORDER BY lti_resource_links.created_at) AS rk
        FROM #{Lti::ResourceLink.quoted_table_name}
      )
      SELECT copied_resource_links.id as copy_id, original_resource_links.id AS orig_id, original_resource_links.url
      FROM #{Lti::ResourceLink.quoted_table_name} AS copied_resource_links
      INNER JOIN original_resource_links ON copied_resource_links.lookup_uuid = original_resource_links.lookup_uuid
                                        AND copied_resource_links.root_account_id = original_resource_links.root_account_id
                                        AND copied_resource_links.id <> original_resource_links.id
                                        AND original_resource_links.url IS NOT NULL
                                        AND original_resource_links.url <> copied_resource_links.url
                                        AND original_resource_links.rk = 1
      WHERE copied_resource_links.created_at > '2022-06-06'
        AND copied_resource_links.context_type = 'Course'"
    )
  end

  def self.run
    resource_links_to_update.group_by { |r| r["orig_id"] }.each do |orig_id, resource_links|
      copied_ids = ActiveRecord::Base.sanitize_sql(resource_links.map { |rl| rl["copy_id"] }.join(","))
      next if resource_links.empty?

      ActiveRecord::Base.connection.execute(
        "update #{Lti::ResourceLink.quoted_table_name}
          set url = orig_resource_link.url
        from (select url from #{Lti::ResourceLink.quoted_table_name} where id = #{ActiveRecord::Base.sanitize_sql(orig_id)}) orig_resource_link
        where id in (#{copied_ids})
        "
      )
    end
  end
end
