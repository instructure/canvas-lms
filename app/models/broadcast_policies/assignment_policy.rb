module BroadcastPolicies
  class AssignmentPolicy
    extend DatesOverridable::ClassMethods
    attr_reader :assignment

    def initialize(assignment)
      @assignment = assignment
    end

    def should_dispatch_assignment_due_date_changed?
      accepting_messages? &&
      assignment.changed_in_state(:published, :fields => :due_at) &&
      !AssignmentPolicy.due_dates_equal?(assignment.due_at, prior_version.due_at) &&
      created_before(3.hours.ago)
    end

    def should_dispatch_assignment_changed?
      accepting_messages? &&
      assignment.published? &&
      !assignment.muted? &&
      created_before(30.minutes.ago) &&
      (assignment.points_possible != prior_version.points_possible || assignment.assignment_changed)
    end

    private
    def accepting_messages?
      assignment.context.available? &&
      prior_version
    end

    def prior_version
      assignment.prior_version
    end

    def created_before(time)
      assignment.created_at < time
    end
  end
end
