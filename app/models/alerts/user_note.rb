# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Alerts
  class UserNote

    def initialize(course, student_ids, teacher_ids)
      @user_notes_enabled = course.root_account.enable_user_notes?
      if @user_notes_enabled
        @last_note_for_user = {}
        @start_at = course.start_at || course.created_at
        @today = Time.now.beginning_of_day
        data = {}
        student_ids.each { |id| data[id] = {} }
        scope = ::UserNote.active.
            where(:created_by_id => teacher_ids, :user_id => student_ids)
        note_dates = scope.group(:user_id, :created_by_id).maximum(:created_at)
        note_dates.each do |key, date|
          student = data[key.first]
          (student[:last_user_note] ||= {})[key.last] = date
        end
        data.each do |student_id, user_data|
          user_data[:last_user_note] ||= {}
          @last_note_for_user[student_id] = user_data[:last_user_note].values.max
        end
      end
    end

    def should_not_receive_message?(user_id, threshold)
      return true unless @user_notes_enabled
      (@last_note_for_user[user_id] || @start_at) + threshold.days > @today
    end

  end
end