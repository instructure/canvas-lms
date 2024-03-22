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
#

class Announcement < DiscussionTopic
  belongs_to :context, polymorphic: [:course, :group]

  has_a_broadcast_policy
  include HasContentTags
  include Plannable

  sanitize_field :message, CanvasSanitize::SANITIZE

  before_save :infer_content
  before_save :respect_context_lock_rules
  after_save :create_observer_alerts_job
  validates :context_id, presence: true
  validates :context_type, presence: true
  validates :message, presence: true

  acts_as_list scope: { context: self, type: "Announcement" }

  scope :between, lambda { |start_date, end_date|
    where("COALESCE(delayed_post_at, posted_at, created_at) BETWEEN ? AND ?", start_date, end_date)
  }

  scope :ordered_between, lambda { |start_date, end_date|
    between(start_date, end_date).order(Arel.sql("COALESCE(delayed_post_at, posted_at, created_at) DESC"))
  }

  scope :ordered_between_by_context, lambda { |start_date, end_date|
    between(start_date, end_date).order(Arel.sql("context_id, COALESCE(delayed_post_at, posted_at, created_at) DESC"))
  }

  def validate_draft_state_change
    _old_draft_state, new_draft_state = changes["workflow_state"]
    errors.add :workflow_state, I18n.t("#announcements.error_draft_state", "This topic cannot be set to draft state because it is an announcement.") if new_draft_state == "unpublished"
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
      context_type: "Course",
      context_id: course,
      workflow_state: "active"
    ).update_all(locked: true)
  end

  def course_broadcast_data
    context&.broadcast_data
  end

  set_broadcast_policy! do
    dispatch :new_announcement
    to { users_with_permissions(active_participants_include_tas_and_teachers(true) - [user]) }
    whenever do |record|
      record.send_notification_for_context? and
        ((record.just_created and !(record.post_delayed? || record.unpublished?)) || record.changed_state(:active, :unpublished) || record.changed_state(:active, :post_delayed))
    end
    data { course_broadcast_data }

    dispatch :announcement_created_by_you
    to { user }
    whenever do |record|
      record.send_notification_for_context? and
        ((record.just_created and !(record.post_delayed? || record.unpublished?)) || record.changed_state(:active, :unpublished) || record.changed_state(:active, :post_delayed))
    end
    data { course_broadcast_data }
  end

  set_policy do
    given { |user| self.user.present? && self.user == user }
    can :update and can :read

    given { |user| self.user.present? && self.user == user && !comments_disabled? }
    can :reply

    given { |user| self.user.present? && self.user == user && discussion_entries.active.empty? }
    can :delete

    given do |user|
      grants_right?(user, :read) &&
        (context.is_a?(Group) ||
         (user &&
          (context.grants_right?(user, :read_as_admin) ||
           (context.is_a?(Course) &&
            context.includes_user?(user)))))
    end
    can :read_replies

    given { |user, session| context.grants_right?(user, session, :read_announcements) && visible_for?(user) }
    can :read

    given { |user, session| context.grants_right?(user, session, :post_to_forum) && !locked? && !comments_disabled? }
    can :reply

    given { |user, session| context.is_a?(Group) && context.grants_right?(user, session, :create_forum) }
    can :create

    given { |user, session| context.grants_all_rights?(user, session, :read_announcements, :moderate_forum) }
    can :update and can :read_as_admin and can :delete and can :create and can :read and can :attach

    given { |user, session| context.grants_all_rights?(user, session, :read_announcements, :moderate_forum) && !comments_disabled? }
    can :reply

    given do |user, session|
      allow_rating && (!only_graders_can_rate ||
                            context.grants_right?(user, session, :manage_grades))
    end
    can :rate
  end

  def is_announcement
    true
  end

  def homeroom_announcement?(context)
    context.is_a?(Course) && context.elementary_homeroom_course?
  end

  # no one should receive discussion entry notifications for announcements
  def subscribers
    []
  end

  def subscription_hold(_user, _session)
    :topic_is_announcement
  end

  def can_unpublish?(*)
    false
  end

  def published?
    true
  end

  def assignment
    nil
  end

  def create_observer_alerts_job
    return if !saved_changes.key?("workflow_state") || saved_changes["workflow_state"][1] != "active"
    return if context_type != "Course"

    create_observer_alerts if course.enrollments.active.of_observer_type.where.not(associated_user_id: nil).exists?
  end

  def create_observer_alerts
    course.enrollments.active.of_observer_type.where.not(associated_user_id: nil).find_each do |enrollment|
      observer = enrollment.user
      student = enrollment.associated_user
      next unless visible_for?(student)

      threshold = ObserverAlertThreshold.where(observer:, alert_type: "course_announcement", student:).first
      next unless threshold

      ObserverAlert.create!(observer:,
                            student:,
                            observer_alert_threshold: threshold,
                            context: self,
                            alert_type: "course_announcement",
                            action_date: updated_at,
                            title: I18n.t("Course announcement: \"%{title}\" in %{course_code}", {
                                            title: self.title,
                                            course_code: course.course_code
                                          }))
    end
  end
  handle_asynchronously :create_observer_alerts, priority: Delayed::LOW_PRIORITY, max_attempts: 1
end
