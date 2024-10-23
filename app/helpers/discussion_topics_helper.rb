# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module DiscussionTopicsHelper
  def topic_page_title(topic)
    if topic.is_announcement
      if topic.new_record?
        t("#title.new_announcement", "New Announcement")
      else
        t("#title.edit_announcement", "Edit Announcement")
      end
    elsif topic.new_record?
      t("#title.new_topic", "New Discussion Topic")
    else
      t("#title.edit_topic", "Edit Discussion Topic")
    end
  end

  def validate_possible_points_with_checkpoints(input)
    total_points_possible = 0
    input[:checkpoints].each { |checkpoint| total_points_possible += checkpoint[:points_possible].to_i }
    I18n.t("The value of possible points for this assignment cannot exceed 999999999.") unless total_points_possible < 1_000_000_000
  end
end
