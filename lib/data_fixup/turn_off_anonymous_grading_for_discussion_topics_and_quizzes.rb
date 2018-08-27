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
#

module DataFixup
  module TurnOffAnonymousGradingForDiscussionTopicsAndQuizzes
    def self.run
      Assignment.find_ids_in_ranges(batch_size: 10_000) do |start_id, end_id|
        Assignment.where(
          id: start_id..end_id,
          anonymous_grading: true,
          submission_types: ['discussion_topic', 'online_quiz']
        ).in_batches { |batch| batch.update_all(anonymous_grading: false, updated_at: Time.zone.now) }
      end
    end
  end
end
