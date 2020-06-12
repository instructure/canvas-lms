require_relative '../rails_helper'

RSpec.describe 'Enrollments API Controller - Custom Placement', type: :request do

  include_context 'stubbed_network'

  before(:each) do
    course_with_teacher_logged_in()

    @student    = user_with_pseudonym
    @course.enroll_user(@student, 'StudentEnrollment')
    @student    = @student.reload
    @enrollment = @student.enrollments.first
  end

  context 'when custom placement setting turned off' do
    describe 'access based on settings service' do
      it "doesnt process the action and returns error code with message" do
        allow_any_instance_of(EnrollmentsApiController).to receive(:custom_placement_enabled?).and_return(false)

        post custom_placement_path(course_id: @course.id, id: @enrollment.id), xhr: true, params: { content_tag: { id: 1 } }

        json = JSON.parse(response.body)

        expect(response.status).to eq(422)
        expect(json).to have_key("error")
        expect(json["error"]).to eq('Custom placement not enabled')
      end
    end
  end

  context 'when custom placement setting turned on' do
    describe 'access based on settings service' do
      it "it processes the action and return success status" do
        allow_any_instance_of(TeacherEnrollment).to receive(:has_permission_to?).and_return(true)

        content_tag = instance_double(ContentTag)
        expect(ContentTag).to receive(:find).with(anything).and_return(content_tag)

        allow_any_instance_of(Enrollment).to receive_message_chain(:user, :send_later_if_production_enqueue_args).and_return(true)

        post custom_placement_path(course_id: @course.id, id: @enrollment.id), xhr: true, params: { content_tag: { id: 1 } }

        json = JSON.parse(response.body)

        expect(response.status).to eq(200)
        expect(json).to be_empty
      end
    end
  end
end
