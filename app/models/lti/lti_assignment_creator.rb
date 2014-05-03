module Lti
  class LtiAssignmentCreator
    SUBMISSION_TYPES_MAP = {
        'online_upload' => 'file',
        'online_url' => 'url',
        'external_tool' => ['text', 'url']
    }

    def initialize(assignment, source_id = nil)
      @assignment = assignment
      @source_id = source_id
    end

    def convert
      LtiOutbound::LTIAssignment.new.tap do |lti_assignment|
        lti_assignment.id = @assignment.id
        lti_assignment.source_id = @source_id
        lti_assignment.title = @assignment.title
        lti_assignment.points_possible = @assignment.points_possible
        lti_assignment.return_types = @assignment.submission_types_array.map{|type| SUBMISSION_TYPES_MAP[type]}.flatten.compact
        lti_assignment.allowed_extensions = @assignment.allowed_extensions
      end
    end
  end
end
