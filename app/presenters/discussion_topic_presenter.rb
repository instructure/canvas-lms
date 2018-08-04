#
# Copyright (C) 2013 - present Instructure, Inc.
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

class DiscussionTopicPresenter
  attr_reader :topic, :assignment, :user, :override_list

  include TextHelper

  def initialize(discussion_topic = DiscussionTopic.new, current_user = User.new)
    @topic = discussion_topic
    @user  = current_user

    if @topic.for_assignment?
      @assignment = AssignmentOverrideApplicator.assignment_overridden_for(@topic.assignment, @user)
    end
  end

  # Public: Determine if the given user has permissions to manage this discussion.
  #
  # Returns a boolean.
  def has_manage_actions?(user)
    can_grade?(user) || show_peer_reviews?(user) || should_show_rubric?(user)
  end

  # Public: Determine if the given user can grade the discussion's assignment.
  #
  # user - The user whose permissions we're testing.
  #
  # Returns a boolean.
  def can_grade?(user=@user)
    topic.for_assignment? &&
    (assignment.grants_right?(user, :grade) ||
      assignment.context.grants_right?(user, :manage_assignments))
  end

  # Public: Determine if the given user has permissions to view peer reviews.
  #
  # user - The user whose permissions we're testing.
  #
  # Returns a boolean.
  def show_peer_reviews?(user)
    if assignment.present?
      assignment.grants_right?(user, :grade) &&
        assignment.has_peer_reviews?
    else
      false
    end
  end

  def peer_reviews_for(user)
    reviews = user.assigned_submission_assessments.for_assignment(assignment.id).to_a
    if reviews.any?
      valid_student_ids = assignment.context.participating_students.where(:id => reviews.map(&:user_id)).pluck(:id).to_set
      reviews = reviews.select{|r| valid_student_ids.include?(r.user_id)}
    end
    reviews
  end

  # Public: Determine if this discussion's assignment has an attached rubric.
  #
  # Returns a boolean.
  def has_attached_rubric?
    !!assignment.rubric_association.try(:rubric)
  end

  # Public: Determine if the given user can manage rubrics.
  #
  # user - The user whose permissions we're testing.
  #
  # Returns a boolean.
  def should_show_rubric?(user)
    if assignment
      has_attached_rubric? || assignment.grants_right?(user, :update)
    else
      false
    end
  end

  # Public: Determine if comment feature is disabled for the context/announcement.
  #
  # Returns a boolean.
  def comments_disabled?
    topic.comments_disabled?
  end

  # Public: Determine if the discussion's context has a large roster flag set.
  #
  # Returns a boolean.
  def large_roster?
    if topic.context.respond_to?(:large_roster?)
      topic.context.large_roster?
    else
      !!topic.context.try(:context).try(:large_roster?)
    end
  end

  # Public: Determine if SpeedGrader should be enabled for the Discussion Topic.
  #
  # Returns a boolean.
  def allows_speed_grader?
    !large_roster? && topic.assignment.published?
  end

  def author_link_attrs
    attrs = {
      class: "author",
      title: I18n.t("Author's Name"),
    }

    if topic.context.is_a?(Course)
      student_enrollment = topic.user.enrollments.active.where(
        course_id: topic.context.id,
        type: "StudentEnrollment",
      ).first

      if student_enrollment
        attrs[:"data-student_id"] = student_enrollment.user_id
        attrs[:"data-course_id"] = student_enrollment.course_id
        attrs[:class] << " student_context_card_trigger"
      end
    end

    attrs
  end

end
