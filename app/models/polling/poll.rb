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
  class Poll < ActiveRecord::Base
    attr_accessible :user, :question, :description

    belongs_to :user
    has_many :poll_choices, class_name: 'Polling::PollChoice', dependent: :destroy, order: :position
    has_many :poll_submissions, class_name: 'Polling::PollSubmission', dependent: :destroy
    has_many :poll_sessions, class_name: 'Polling::PollSession', dependent: :destroy

    validates_presence_of :question, :user
    validates_length_of :question, maximum: 255, allow_nil: true
    validates_length_of :description, maximum: 255, allow_nil: true

    set_policy do
      given { |user| self.user.present? && self.user == user }
      can :update and can :read and can :delete

      given { |user| user.roles.include?("teacher") }
      can :create

      given do |user, http_session|
        user.roles.include?("admin") && self.poll_sessions.with_each_shard do |scope|
          scope.includes(:course).any? { |session| session.course.grants_right?(user, http_session, :read_as_admin) }
        end.any?
      end
      can :create and can :update and can :read and can :delete and can :submit

      given do |user|
        self.poll_sessions.with_each_shard do |scope|
          scope.where(["course_id IN (?) AND (course_section_id IS NULL OR course_section_id IN (?))",
                       Enrollment.where(user_id: user).active.select(:course_id),
                       Enrollment.where(user_id: user).active.select(:course_section_id)]).exists?
        end.any?
      end
      can :read
    end

    def associated_shards
      user.associated_shards
    end

    def closed_and_viewable_for?(user)
      results = poll_sessions.with_each_shard do |scope|
        scope
        .joins(:poll_submissions)
        .where(["polling_poll_submissions.user_id = ? AND is_published=? AND course_id IN (?) AND (course_section_id IS NULL OR course_section_id IN (?))",
                user,
                false,
                Enrollment.where(user_id: user).active.select(:course_id),
                Enrollment.where(user_id: user).active.select(:course_section_id)]
              )
        .order('polling_poll_sessions.created_at DESC')
        .limit(1)
        .exists?
      end

       results.any?
    end

    def total_results
      results = poll_submissions.with_each_shard { |scope| scope.group('poll_choice_id').count }
      Hash[*results.flatten]
    end
  end
end
