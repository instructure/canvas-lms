#
# Copyright (C) 2016 - present Instructure, Inc.
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
  module AssociateGradedDiscussionAttachments
    def self.run
      DiscussionTopic.find_ids_in_ranges do |min_id, max_id|

        rows = DiscussionTopic.where(:id => min_id..max_id).where.not(:assignment_id => nil).
          joins(:discussion_entries).where.not(:discussion_entries => {:attachment_id => nil}).
          pluck("discussion_topics.assignment_id, discussion_entries.user_id, discussion_entries.attachment_id")

        map = {}
        rows.each do |asmt_id, user_id, att_id| # group attachment_ids by user/assignment pairs
          k = [asmt_id, user_id]
          map[k] ||= []
          map[k] << att_id
        end

        map.each do |k, attachment_ids|
          assignment_id, user_id = k
          sub = Submission.where(:assignment_id => assignment_id, :user_id => user_id, :attachment_ids => nil).first
          if sub
            sub.attachment_ids = attachment_ids.sort.map(&:to_s).join(',')
            sub.save!
          end
        end
      end
    end
  end
end