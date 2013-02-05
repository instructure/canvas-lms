class DiscussionTopicPresenter
  attr_reader :topic, :assignment, :user

  include TextHelper

  def initialize(discussion_topic = DiscussionTopic.new, current_user = User.new)
    @topic = discussion_topic
    @user  = current_user

    @assignment = if @topic.for_assignment?
      AssignmentOverrideApplicator.assignment_overridden_for(@topic.assignment, @user)
    else
      nil
    end
  end

  # Public: Return a presenter using an unoverridden copy of the topic's assignment
  #
  # Returns a DiscussionTopicPresenter
  def unoverridden
    self.class.new(@topic, nil)
  end
  
  # Public: Return a date string for the discussion assignment's lock at date.
  #
  # due_date - A due date as a hash.
  #
  # Returns a date or date/time string.
  def lock_at(due_date = {})
    formatted_date_string(:lock_at, due_date)
  end

  # Public: Return a date string for the discussion assignment's unlock at date.
  #
  # due_date - A due date as a hash.
  #
  # Returns a date or date/time string.
  def unlock_at(due_date = {})
    formatted_date_string(:unlock_at, due_date)
  end

  # Public: Return a date string for the given due date.
  #
  # due_date - A due date as a hash.
  #
  # Returns a date or date/time string.
  def due_at(due_date = {})
    formatted_date_string(:due_at, due_date)
  end

  def formatted_date_string(date_field, date_hash = {})
    date = date_hash[:override].try(date_field) if date_hash[:override].present?
    date ||= assignment.try(date_field)
 
    formatted_date = date.present? ? datetime_string(date) : '-'
    formatted_date.match(/11:59/) ? date_string(date) : formatted_date
  end

  # Public: Determine if multiple due dates are visible to user.
  #
  # Returns a boolean
  def multiple_due_dates?
    assignment.multiple_due_dates_apply_to?(user)
  end
  
  # Public: Return all due dates visible to user, filtering out assignment info
  #   if it isn't needed (e.g. if all sections have overrides).
  #
  # Returns an array of due date hashes.
  def visible_due_dates
    return [] unless assignment

    due_dates  = assignment.due_dates_visible_to(user)
    section_overrides = due_dates.select { |d| d[:override].try(:set_type) == 'CourseSection' }

    if section_overrides.count > 0 && section_overrides.count == topic.context.course_sections.count
      due_dates.delete_if { |d| d[:override].nil? }
    end
    
    # Sort by due_at, nils and earliest first
    due_dates.sort{ |date1, date2|
      due_at1 = date1[:due_at]
      due_at2 = date2[:due_at]
      (due_at1 and due_at2) ? due_at1 <=> due_at2 : (due_at1 ? 1 : -1)
    }
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
  def can_grade?(user)
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
    assignment.rubric_association.try(:rubric)
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
end
