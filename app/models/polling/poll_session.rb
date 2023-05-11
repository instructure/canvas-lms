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
#

module Polling
  class PollSession < ActiveRecord::Base
    belongs_to :course
    belongs_to :course_section
    belongs_to :poll, class_name: "Polling::Poll"
    has_many :poll_submissions, class_name: "Polling::PollSubmission", dependent: :destroy
    validates :poll, :course, presence: true
    validate :section_belongs_to_course

    set_policy do
      given do |user, session|
        poll.grants_right?(user, session, :update)
      end
      can :read and can :create and can :delete and can :publish

      given do |user, session|
        visible_to?(user, session)
      end
      can :read

      given do |user, session|
        visible_to?(user, session) && is_published?
      end
      can :submit
    end

    def self.available_for(user)
      enrollments = Enrollment.where(user_id: user).active
      subquery = PollSession.where(course_section_id: nil)
                            .or(PollSession.where(course_section_id:
                                enrollments.select(:course_section_id)))
      PollSession.where(course_id: enrollments.select(:course_id)).merge(subquery)
    end

    def results
      poll_submissions.group("poll_choice_id").count
    end

    def has_submission_from?(user)
      poll_submissions.where(user_id: user).exists?
    end

    def publish!
      self.is_published = true
      save!
    end

    def close!
      self.is_published = false
      save!
    end

    def visible_to?(user, session)
      course.grants_right?(user, session, :read) &&
        (course_section ? course_section.grants_right?(user, session, :read) : true)
    end

    private

    def section_belongs_to_course
      if course && course_section && !course.course_sections.include?(course_section)
        errors.add(:base, I18n.t("polling.poll_sessions.validations.section_belongs_to_course",
                                 "That course section does not belong to the existing course."))
      end
    end
  end
end
