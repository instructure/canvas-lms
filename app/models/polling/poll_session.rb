#
# Copyright (C) 2014 Instructure, Inc.
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

module Polling
  class PollSession < ActiveRecord::Base
    attr_accessible :poll, :course, :course_section, :course_id, :course_section_id, :has_public_results

    belongs_to :course
    belongs_to :course_section
    belongs_to :poll, class_name: 'Polling::Poll'
    has_many :poll_submissions, class_name: 'Polling::PollSubmission'
    validates_presence_of :poll, :course
    validate :section_belongs_to_course

    set_policy do
      given do |user, session|
        self.poll.grants_right?(user, session, :update)
      end
      can :read and can :create and can :delete and can :publish

      given do |user, session|
        self.cached_context_grants_right?(user, session, :read) &&
          self.is_published? &&
          (self.course_section ? self.course_section.grants_right?(user, session, :read) : true)
      end
      can :read and can :submit
    end

    def self.available_for(user)
      PollSession.where("course_id IN (?) AND (course_section_id IS NULL OR course_section_id IN (?))",
                        user.enrollments.map(&:course_id).compact,
                        user.enrollments.map(&:course_section_id).compact)
    end

    def results
      poll_submissions.each_with_object(Hash.new(0)) do |submission, poll_results|
        poll_results[submission.poll_choice.id] += 1
      end
    end

    def has_submission_from?(user)
      !!poll_submissions.find_by_user_id(user.id)
    end

    def publish!
      self.is_published = true
      save!
    end

    def close!
      self.is_published = false
      save!
    end

    private
    def section_belongs_to_course
      if self.course && self.course_section
        unless self.course.course_sections.include?(course_section)
          errors.add(:base, I18n.t('polling.poll_sessions.validations.section_belongs_to_course',
                                   'That course section does not belong to the existing course.'))
        end
      end
    end
  end
end
