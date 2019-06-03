require_relative '../../../rails_helper'

RSpec.describe BasicLTI::BasicOutcomes::LtiResponse do
  include_context 'stubbed_network'

  let(:lti_response) { BasicLTI::BasicOutcomes::LtiResponse.new(double('lti_request')) }

  let!(:teacher) { teacher_in_course; @teacher }
  let!(:student) { student_in_course(course: @course).user }
  let!(:assignment) { @course.assignments.create!({
          title: "value for title",
          description: "value for description",
          due_at: Time.now,
          points_possible: "1.5",
          submission_types: 'external_tool',
          external_tool_tag_attributes: {url: tool.url}
      }) }
  let!(:submission) { assignment.submit_homework(student) }
  let(:tool) do
    @course.context_external_tools.create(:name => "a", :url => "http://google.com", :consumer_key => '12345', :shared_secret => 'secret')
  end
  let(:submission_hash) {{
    body: 'some body text',
    submission_type: 'online_text_entry',
    grade: 0.5
  }}

  before do
    submission.with_versioning(:explicit => true) {
      submission.update_attributes!(:graded_at => Time.zone.now, :grader_id => teacher.id, :score => 100) }

    submission.with_versioning(:explicit => true) {
      submission.update_attributes!(:graded_at => Time.zone.now, :grader_id => teacher.id, :score => 90) }

    submission.with_versioning(:explicit => true) {
      submission.update_attributes!(:graded_at => Time.zone.now, :grader_id => teacher.id, :score => 80) }
  end

  context '#create_homework_submission' do
    context 'featured' do
      before do
        allow(PipelineService).to receive(:publish)
        allow(SettingsService).to receive(:get_settings).and_return('lti_keep_highest_score' => true)
      end

      it 'should call the shimmed method' do
        lti_response.instance_variable_set('@submission', submission)

        expect(lti_response).to receive(:update_submission_with_best_score)

        lti_response.create_homework_submission(tool, submission_hash, assignment, student, 1.0, nil)
      end

      it 'sets the score and grade to the highest in the submission history' do
        expect_any_instance_of(Submission).to receive(:update_columns).with({grade: '100', score: 100.0, published_grade: '100', published_score: 100.0})

        lti_response.instance_variable_set('@submission', submission)

        lti_response.create_homework_submission(tool, submission_hash, assignment, student, 1.0, nil)
      end

      context "no submission" do
        it 'wont update' do
          lti_response.instance_variable_set('@submission', nil)

          expect_any_instance_of(Submission).to_not receive(:update)

          lti_response.create_homework_submission(tool, submission_hash, assignment, student, 1.0, nil)
        end
      end
    end

    context 'unfeatured' do
      before do
        allow(SettingsService).to receive(:get_settings).and_return('lti_keep_highest_score' => false)
      end

      it 'should not call the shimmed method' do
        expect(lti_response).to_not receive(:update_submission_with_best_score)
        lti_response.create_homework_submission(tool, submission_hash, assignment, student, 1.0, nil)
      end
    end
  end
end
