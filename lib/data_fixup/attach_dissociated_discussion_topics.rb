#
# Copyright (C) 2013 - present Instructure, Inc.
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
  module AttachDissociatedDiscussionTopics
    def self.run
      return unless DiscussionTopic.connection.adapter_name == 'PostgreSQL'

      ActiveRecord::Base.connection.execute(<<-SQL)
        UPDATE #{DiscussionTopic.quoted_table_name} SET assignment_id = old_assignment_id, updated_at = NOW()
        FROM #{Assignment.quoted_table_name}
        WHERE discussion_topics.old_assignment_id = assignments.id
        AND discussion_topics.assignment_id IS NULL
        AND discussion_topics.context_id = assignments.context_id
        AND discussion_topics.context_type = assignments.context_type
        AND discussion_topics.title = assignments.title
        AND discussion_topics.updated_at > '2013-04-14T18:00:00Z'
        AND assignments.workflow_state <> 'deleted'
        AND discussion_topics.workflow_state <> 'deleted'
        AND (assignments.description LIKE '%download?verifier=%' OR assignments.description LIKE '%/download?%')
      SQL
    end
  end
end
