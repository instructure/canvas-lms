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
    (assignment.grants_right?(user, nil, :grade) ||
      assignment.context.grants_right?(user, nil, :manage_assignments))
  end

  # Public: Determine if the given user has permissions to view peer reviews.
  #
  # user - The user whose permissions we're testing.
  #
  # Returns a boolean.
  def show_peer_reviews?(user)
    if assignment.present?
      assignment.grants_right?(user, nil, :grade) &&
        assignment.has_peer_reviews?
    else
      false
    end
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
      has_attached_rubric? || assignment.grants_right?(user, nil, :update)
    else
      false
    end
  end

  # Public: Determine if comment feature is disabled for the context/announcement.
  #
  # Returns a boolean.
  def comments_disabled?
    !!((topic.is_a?(Announcement) &&
      topic.context.is_a?(Course) &&
      topic.context.settings[:lock_all_announcements]))
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
    !large_roster? && draft_state_allows_speedgrader?
  end

  def draft_state_allows_speedgrader?
    topic.context.draft_state_enabled? ? topic.assignment.published? : true
  end
end
