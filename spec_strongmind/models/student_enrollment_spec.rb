require_relative '../rails_helper'

RSpec.describe StudentEnrollment do
  include_context "stubbed_network"

  it 'publishes pipeline events' do
    env = {
      PIPELINE_ENDPOINT: 'blah',
      PIPELINE_USER_NAME: 'blah',
      PIPELINE_PASSWORD: 'blah',
      SIS_ENROLLMENT_UPDATE_API_KEY: 'blah',
      SIS_ENROLLMENT_UPDATE_ENDPOINT: 'blah',
      SIS_UNIT_GRADE_ENDPOINT_API_KEY: 'blah',
      SIS_UNIT_GRADE_ENDPOINT: 'blah'
    }

    with_modified_env env do
      expect(PipelineService).to receive(:publish).with(an_instance_of(StudentEnrollment))
      expect(PipelineService).to receive(:publish).with(an_instance_of(Course))

      course_with_student
    end
  end
end
