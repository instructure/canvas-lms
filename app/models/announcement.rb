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
#

class Announcement < DiscussionTopic

  belongs_to :context, polymorphic: [:course, :group]

  has_a_broadcast_policy
  include HasContentTags
  include Plannable

  sanitize_field :message, CanvasSanitize::SANITIZE

  before_save :infer_content
  before_save :respect_context_lock_rules
  after_save :create_alert
  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_presence_of :message

  acts_as_list scope: { context: self, type: 'Announcement' }

  def validate_draft_state_change
    old_draft_state, new_draft_state = self.changes['workflow_state']
    self.errors.add :workflow_state, I18n.t('#announcements.error_draft_state', "This topic cannot be set to draft state because it is an announcement.") if new_draft_state == 'unpublished'
  end

  def infer_content
    self.title ||= t(:no_title, "No Title")
  end
  protected :infer_content

  def respect_context_lock_rules
    self.locked = true if !locked? &&
            context.is_a?(Course) &&
            context.lock_all_announcements?
  end
  protected :respect_context_lock_rules

  def self.lock_from_course(course)
    Announcement.where(
      :context_type => 'Course',
      :context_id => course,
      :workflow_state => 'active'
    ).update_all(:locked => true)
  end

  set_broadcast_policy! do
    dispatch :new_announcement
    to { users_with_permissions(active_participants_include_tas_and_teachers(true) - [user]) }
    whenever { |record|
      record.send_notification_for_context? and
        ((record.just_created and !(record.post_delayed? || record.unpublished?)) || record.changed_state(:active, :unpublished) || record.changed_state(:active, :post_delayed))
    }

    dispatch :announcement_created_by_you
    to { user }
    whenever { |record|
      record.send_notification_for_context? and
        ((record.just_created and !(record.post_delayed? || record.unpublished?)) || record.changed_state(:active, :unpublished) || record.changed_state(:active, :post_delayed))
    }
  end

  set_policy do
    given { |user| self.user.present? && self.user == user }
    can :update and can :reply and can :read

    given { |user| self.user.present? && self.user == user && self.discussion_entries.active.empty? }
    can :delete

    given do |user|
      self.grants_right?(user, :read) &&
       (self.context.is_a?(Group) ||
        (user &&
         (self.context.grants_right?(user, :read_as_admin) ||
          (self.context.is_a?(Course) &&
           self.context.includes_user?(user)))))
    end
    can :read_replies

    given { |user, session| self.context.grants_right?(user, session, :read_announcements) && self.visible_for?(user) }
    can :read

    given { |user, session| self.context.grants_right?(user, session, :post_to_forum) && !self.locked?}
    can :reply

    given { |user, session| self.context.is_a?(Group) && self.context.grants_right?(user, session, :create_forum) }
    can :create

    given { |user, session| self.context.grants_all_rights?(user, session, :read_announcements, :moderate_forum) } #admins.include?(user) }
    can :update and can :read_as_admin and can :delete and can :reply and can :create and can :read and can :attach

    given do |user, session|
      self.allow_rating && (!self.only_graders_can_rate ||
                            self.context.grants_right?(user, session, :manage_grades))
    end
    can :rate
  end

  def is_announcement; true end

  # no one should receive discussion entry notifications for announcements
  def subscribers
    []
  end

  def subscription_hold(user, context_enrollment, session)
    :topic_is_announcement
  end

  def can_unpublish?(opts=nil)
    false
  end

  def published?
    true
  end

  def assignment
    nil
  end

  def create_alert
    return if !saved_changes.keys.include?('workflow_state') || saved_changes['workflow_state'][1] != 'active'
    return if self.context_type != 'Course'

    observer_enrollments = self.course.enrollments.active.where(type: 'ObserverEnrollment')
    observer_enrollments.each do |enrollment|
      observer = enrollment.user
      student = enrollment.associated_user
      threshold = ObserverAlertThreshold.where(observer: observer, alert_type: 'course_announcement', student: student).first
      next unless threshold

      ObserverAlert.create!(observer: observer, student: student, observer_alert_threshold: threshold,
                            context: self, alert_type: 'course_announcement', action_date: self.updated_at,
                            title: I18n.t("Course announcement: \"%{title}\" in %{course_code}", {
                              title: self.title,
                              course_code: self.course.course_code
                            }))
    end
  end
end
