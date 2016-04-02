module BroadcastPolicies
  class AssignmentParticipants
    def initialize(assignment, excluded_ids=nil)
      @assignment = assignment
      @excluded_ids = excluded_ids
    end
    attr_reader :assignment, :excluded_ids
    delegate :context, :participants, to: :assignment

    def to
      all_participants - excluded_enrollment_users
    end

    private
    def all_participant_ids
      all_participants.map(&:id)
    end

    def all_participants
      @_all_participants ||= participants({
        include_observers: true,
        excluded_user_ids: excluded_ids
      })
    end

    def excluded_enrollment_users
      excluded_enrollments.map(&:user)
    end

    def excluded_enrollments
      Enrollment.where({
        user_id: all_participant_ids
      }).not_yet_started(context)
    end
  end
end
