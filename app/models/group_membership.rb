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

class GroupMembership < ActiveRecord::Base
  include Workflow
  extend RootAccountResolver

  belongs_to :group
  belongs_to :user

  validates :group_id, :user_id, :workflow_state, :uuid, presence: true
  before_validation :assign_uuid
  before_validation :verify_section_homogeneity_if_necessary
  validate :validate_within_group_limit

  before_save :auto_join
  before_save :capture_old_group_id

  after_save :ensure_mutually_exclusive_membership
  after_save :touch_groups
  after_save :update_group_leadership
  after_save :invalidate_user_membership_cache
  after_commit :update_cached_due_dates
  after_destroy :touch_groups
  after_destroy :update_group_leadership
  after_destroy :invalidate_user_membership_cache

  has_a_broadcast_policy

  scope :include_user, -> { preload(:user) }

  scope :active, -> { where("group_memberships.workflow_state<>'deleted'") }
  scope :moderators, -> { where(moderator: true) }
  scope :active_for_context_and_users, lambda { |context, users|
    joins(:group).active.where(user_id: users, groups: { context_id: context, workflow_state: "available" })
  }

  scope :for_assignments, lambda { |ids|
    active.joins(group: { group_category: :assignments })
          .merge(Group.active)
          .merge(GroupCategory.active)
          .merge(Assignment.active).where(assignments: { id: ids })
  }

  scope :for_collaborative_groups, -> { joins(:group).merge(Group.collaborative) }
  scope :for_non_collaborative_groups, -> { joins(:group).merge(Group.non_collaborative) }

  scope :for_students, ->(ids) { where(user_id: ids) }

  resolves_root_account through: :group

  alias_method :context, :group

  attr_writer :updating_user

  def course_broadcast_data
    group.broadcast_data
  end

  set_broadcast_policy do |p|
    p.dispatch :new_context_group_membership
    p.to { user }
    p.whenever do |record|
      record.previously_new_record? &&
        record.accepted? &&
        record.group&.context_available? &&
        record.group.can_participate?(user) &&
        record.sis_batch_id.blank?
    end
    p.data { course_broadcast_data }

    p.dispatch :new_context_group_membership_invitation
    p.to { user }
    p.whenever do |record|
      record.previously_new_record? &&
        record.invited? &&
        record.group&.context_available? &&
        record.group.can_participate?(user) &&
        record.sis_batch_id.blank?
    end
    p.data { course_broadcast_data }

    p.dispatch :group_membership_accepted
    p.to { user }
    p.whenever { |record| record.changed_state(:accepted, :requested) }
    p.data { course_broadcast_data }

    p.dispatch :group_membership_rejected
    p.to { user }
    p.whenever { |record| record.changed_state(:rejected, :requested) }
    p.data { course_broadcast_data }

    p.dispatch :new_student_organized_group
    p.to { group.context.participating_admins }
    p.whenever do |record|
      record.group.context.is_a?(Course) &&
        record.previously_new_record? &&
        record.group.group_memberships.count == 1 &&
        record.group.student_organized?
    end
    p.data { course_broadcast_data }
  end

  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid

  # auto accept 'requested' or 'invited' memberships until we implement
  # accepting requests/invitations
  def auto_join
    return true if group.try(:group_category).try(:communities?)

    self.workflow_state = "accepted" if group && (requested? || invited?)
    true
  end
  protected :auto_join

  def update_group_leadership
    GroupLeadership.new(Group.find(group_id)).member_changed_event(self)
  end
  protected :update_group_leadership

  def ensure_mutually_exclusive_membership
    return unless group
    return if deleted?

    peer_groups = group.peer_groups.map(&:id)
    GroupMembership.active.where(group_id: peer_groups, user_id:).destroy_all
  end
  protected :ensure_mutually_exclusive_membership

  def restricted_self_signup?
    group.group_category&.restricted_self_signup?
  end

  def has_common_section_with_me?
    group.has_common_section_with_user?(user)
  end

  def verify_section_homogeneity_if_necessary
    if new_record? && restricted_self_signup? && !has_common_section_with_me?
      errors.add(:user_id, t("errors.not_in_group_section", "%{student} does not share a section with the other members of %{group}.", student: user.name, group: group.name))
      throw :abort
    end
  end
  protected :verify_section_homogeneity_if_necessary

  def validate_within_group_limit
    if new_record? && group.full?
      errors.add(:group_id, t("errors.group_full", "The group is full."))
    end
  end
  protected :validate_within_group_limit

  attr_accessor :old_group_id

  def capture_old_group_id
    self.old_group_id = group_id_was if group_id_changed?
    true
  end
  protected :capture_old_group_id

  def update_cached_due_dates
    return unless update_cached_due_dates?

    assignments = []
    wiki_pages = []
    discussion_topics = []
    quizzes = []

    if group.non_collaborative
      overrides = AssignmentOverride.active.where(set_type: "Group", set_id: group.id)
      parent_assignment_ids = overrides.where.not(assignment_id: nil).pluck(:assignment_id)
      assignments += parent_assignment_ids
      if parent_assignment_ids.any?
        assignments += SubAssignment.active.where(parent_assignment_id: parent_assignment_ids).pluck(:id)
      end
      wiki_pages += overrides.where.not(wiki_page_id: nil).pluck(:wiki_page_id)
      discussion_topics += overrides.where.not(discussion_topic_id: nil).pluck(:discussion_topic_id)
      quizzes += overrides.where.not(quiz_id: nil).pluck(:quiz_id)
    else
      assignments += Assignment.where(context_type: group.context_type, context_id: group.context_id)
                               .where(group_category_id: group.group_category_id).pluck(:id)
      assignments += DiscussionTopic.where(context_type: group.context_type, context_id: group.context_id)
                                    .where.not(assignment_id: nil).where(group_category_id: group.group_category_id).pluck(:assignment_id)
    end

    process_cache_for_assignments(assignments)

    RequestCache.clear if RequestCache.instance_variable_get(:@enabled)

    process_cache_for_wiki_pages(wiki_pages)
    process_cache_for_discussion_topics(discussion_topics)
    process_cache_for_quizzes(quizzes)

    User.touch_and_clear_cache_keys([user], :groups, :todo_list, :submissions, :potential_unread_submission_ids)
  end

  def touch_groups
    groups_to_touch = [group_id]
    groups_to_touch << old_group_id if old_group_id
    Group.where(id: groups_to_touch).touch_all
  end
  protected :touch_groups

  workflow do
    state :accepted
    state :invited do
      event :reject, transitions_to: :rejected
      event :accept, transitions_to: :accepted
    end
    state :requested
    state :rejected
    state :deleted
  end
  alias_method :active?, :accepted?

  def self.serialization_excludes
    [:uuid]
  end

  # true iff 'active' and the pair of user and group's course match one of the
  # provided enrollments
  def active_given_enrollments?(enrollments)
    accepted? && (!group.context.is_a?(Course) ||
     enrollments.any? { |e| e.user == user && e.course == group.context })
  end

  def invalidate_user_membership_cache
    user.clear_cache_key(:groups, :todo_list, :submissions, :potential_unread_submission_ids)
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    save!
  end

  set_policy do
    # for non-communities, people can be placed into groups by users who can
    # manage groups at the context level, but not moderators (hence :manage_groups_manage)
    given do |user, session|
      user && self.user && group &&
        !group.group_category.try(:communities?) &&
        !group.non_collaborative? &&
        (
          (user == self.user && group.grants_right?(user, session, :join)) ||
          (
            group.can_join?(self.user) && group.context &&
            group.context.grants_right?(user, session, :manage_groups_manage)
          )
        )
    end
    can :create

    # for communities, users must initiate in order to be added to a group
    given do |user, _session|
      user && group &&
        user == self.user &&
        group.grants_right?(user, :join) &&
        group.group_category.try(:communities?) &&
        !group.non_collaborative?
    end
    can :create

    # user can read group membership if they can read its group's roster
    given { |user, session| user && group && !group.non_collaborative? && group.grants_right?(user, session, :read_roster) }
    can :read

    given { |user, session| user && group && !group.non_collaborative? && group.grants_right?(user, session, :manage) }
    can :update

    # allow moderators to kick people out
    # hence :manage instead of :manage_groups_delete on the context
    given do |user, session|
      user && self.user && group && !group.non_collaborative? &&
        (
          (user == self.user && group.grants_right?(self.user, session, :leave)) ||
          group.grants_right?(user, session, :manage)
        )
    end
    can :delete

    ##################### Non-Collaborative Group Permission Block ##########################
    # Permissions for non-collaborative group memberships
    given { |user| user && group&.non_collaborative? }
    use_additional_policy do
      given { |user, session| group.grants_right?(user, session, :create) }
      can :create

      given { |user, session| group.grants_right?(user, session, :read) }
      can :read

      given { |user, session| group.grants_right?(user, session, :update) }
      can :update

      given { |user, session| group.grants_right?(user, session, :delete) }
      can :delete
    end
  end

  private

  def update_cached_due_dates?
    workflow_state_changed = previous_changes.key?(:workflow_state)

    workflow_state_changed && group.group_category_id && group.context_type == "Course"
  end

  def process_cache_for_assignments(assignments)
    return if assignments.empty?

    Submission.active.where(user_id: user.id, assignment_id: assignments)
              .update_all(workflow_state: :deleted, updated_at: Time.zone.now)

    AbstractAssignment.where(id: assignments).touch_and_clear_cache_keys(:availability)

    published_assignment_ids = Assignment.where(context_id: group.context_id, workflow_state: "published").pluck(:id)
    assignment_id_sets = [assignments, published_assignment_ids].uniq

    invalidate_visibility_cache(
      service_class: AssignmentVisibility::AssignmentVisibilityService,
      id_sets: assignment_id_sets,
      id_param: :assignment_ids
    )

    SubmissionLifecycleManager.recompute_users_for_course(user.id, group.context_id, assignments)
  end

  def process_cache_for_wiki_pages(wiki_pages)
    return if wiki_pages.empty?

    WikiPage.where(id: wiki_pages).touch_and_clear_cache_keys(:availability)

    active_wiki_page_ids = WikiPage.where(context_type: "Course", context_id: group.context_id, workflow_state: "active").pluck(:id)
    wiki_page_id_sets = [wiki_pages, active_wiki_page_ids].uniq

    invalidate_visibility_cache(
      service_class: WikiPageVisibility::WikiPageVisibilityService,
      id_sets: wiki_page_id_sets,
      id_param: :wiki_page_ids
    )
  end

  def process_cache_for_discussion_topics(discussion_topics)
    return if discussion_topics.empty?

    DiscussionTopic.where(id: discussion_topics).touch_and_clear_cache_keys(:availability)

    active_discussion_ids = DiscussionTopic.where(context_type: "Course", context_id: group.context_id, workflow_state: "active").pluck(:id)
    discussion_id_sets = [discussion_topics, active_discussion_ids].uniq

    invalidate_visibility_cache(
      service_class: UngradedDiscussionVisibility::UngradedDiscussionVisibilityService,
      id_sets: discussion_id_sets,
      id_param: :discussion_topic_ids
    )
  end

  def process_cache_for_quizzes(quizzes)
    return if quizzes.empty?

    Quizzes::Quiz.where(id: quizzes).touch_and_clear_cache_keys(:availability)

    available_quiz_ids = Quizzes::Quiz.where(context_type: "Course", context_id: group.context_id, workflow_state: "available").pluck(:id)
    quiz_id_sets = [quizzes, available_quiz_ids].uniq

    invalidate_visibility_cache(
      service_class: QuizVisibility::QuizVisibilityService,
      id_sets: quiz_id_sets,
      id_param: :quiz_ids
    )
  end

  # Visibility cache keys are generated from input parameters, not from query results.
  # Different API endpoints pass different parameter combinations (specific content IDs,
  # all active IDs, or nil), each with include_concluded true/false. We must invalidate
  # all possible combinations to ensure users immediately lose access when removed from groups.
  def invalidate_visibility_cache(service_class:, id_sets:, id_param:)
    [true, false].each do |include_concluded|
      id_sets.each do |ids|
        service_class.invalidate_cache(
          :course_ids => [group.context_id],
          :user_ids => [user.id],
          id_param => ids,
          :include_concluded => include_concluded
        )
      end

      service_class.invalidate_cache(
        course_ids: [group.context_id],
        user_ids: [user.id],
        include_concluded:
      )
    end
  end
end
