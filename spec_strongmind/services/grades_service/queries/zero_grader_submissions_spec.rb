require_relative '../../../rails_helper'

RSpec.describe GradesService::Queries::ZeroGraderSubmissions, skip: 'todo: fix for running under LMS' do
  include_context "stubbed_network"

  subject {described_class.new}

  describe '#submissions_scope' do
    it 'Will query after the course' do
      course = Course.create(conclude_at: 2.hours.ago)
      assignment = Assignment.create(course: course, due_at: 1.day.ago, workflow_state: 'published')
      submission = Submission.create(assignment: assignment,
        workflow_state: 'unsubmitted',
        score: nil,
        grade: nil,
        cached_due_date: assignment.due_at
      )

      expect(subject.query).to include(submission)
    end
  end
end
