#
# Copyright (C) 2011 Instructure, Inc.
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

class AssignmentReminder < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user
  has_a_broadcast_policy
  before_save :infer_defaults
  attr_accessible :assignment, :user, :reminder_type
  
  def infer_defaults
    self.reminder_type ||= 'due_at'
  end
  
  set_broadcast_policy do |p|
    p.dispatch :assignment_due_date_reminder
    p.to { user }
    p.whenever {|record|
      @remind_due_at
    }
    
    p.dispatch :assignment_publishing_reminder
    p.to { user }
    p.whenever { |record|
      @remind_publishing
    }
    
    p.dispatch :assignment_grading_reminder
    p.to { user }
    p.whenever { |record|
      @remind_grading
    }
    
  end
  
  def update_for(assignment)
    raise "Wrong assignment" unless assignment.id == assignment_id
    time = assignment.due_reminder_time_for(assignment.context, self.user)
    time = assignment.grading_reminder_time_for(assignment.context, self.user) if self.reminder_type == 'grading'
    if self.reminder_type == 'grading' && time && time > 0 && assignment.due_at + time > Time.now
      self.remind_at = assignment.due_at + time
      self.save
      true
    elsif self.reminder_type == 'due_at' && time && time > 0 && assignment.due_at - time > Time.now
      self.remind_at = assignment.due_at - time
      self.save
      true
    else
      self.destroy unless self.new_record?
      false
    end
  end
  
  named_scope :need_sending, lambda {
    {:conditions => ['assignment_reminders.remind_at < ?', Time.now.utc], :limit => 30 }
  }
  
  def remind!
    if reminder_type == 'due_at'
      submission = assignment.find_submission(user) rescue nil
      @remind_due_at = true if !submission || !submission.has_submission?
      save
    elsif reminder_type == 'grading'
      student_count = assignment.context.students.count rescue 0
      graded_submission_count = assignment.submissions.graded.count rescue 0
      if graded_submission_count < (student_count * Assignment.percent_considered_graded)
        @remind_grading = true
        save
      elsif (!assignment.published? rescue false)
        @remind_publishing = true
        save
      end
    end
    self.destroy
  end

  def context
    assignment.try(:context)
  end
end
