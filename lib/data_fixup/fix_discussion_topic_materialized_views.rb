#
# Copyright (C) 2018 - present Instructure, Inc.
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
  class FixDiscussionTopicMaterializedViews
    def self.run
      topic_ids = nil
      Shackles.activate(:slave) do
        result = ActiveRecord::Base.connection.execute(
          "with entries as (
            select count(*) as c, discussion_topic_id
              from #{DiscussionEntry.quoted_table_name}
             group by discussion_topic_id
            ) , matview as (
            select coalesce(array_length(regexp_split_to_array(entry_ids_array, E'\n'), 1) -2,0) as c
             , discussion_topic_id
             from #{DiscussionTopic::MaterializedView.quoted_table_name}
            where generation_started_at < now() - interval '10 minutes'
          )
          select entries.discussion_topic_id as topic
               , entries.c as ent
               , matview.c as mat
            from matview,entries
           where matview.discussion_topic_id=entries.discussion_topic_id
             and matview.c != entries.c;")

         topic_ids = result.map{|d| d['topic']}
      end

      Shackles.activate(:master) do
        DiscussionTopic.where(id: topic_ids).find_each do |dt|
          DiscussionTopic::MaterializedView.for(dt).update_materialized_view_without_send_later
        end
      end
    end
  end
end