require_relative '../rails_helper'

RSpec.describe Submission do
  include_context "stubbed_network"

  context 'callbacks' do
    before do
      allow(PipelineService).to receive(:publish)
    end

    describe '#bust_context_module_cache' do
      before do
        @student    = student_in_course().user
        @module1    = @course.context_modules.create!(name: "Module 1")
        @assignment = @course.assignments.create!(title: "some assignment")
        @assignment.publish
        @assignment_tag = @module1.add_item(id: @assignment.id, type: 'assignment', title: 'Assignment: requires submission')
        @submission = @assignment.submission_for_student(@student)
      end

      context 'when excused was changed' do
        it 'enqueues a module touch' do
          @submission.excused = !@submission.excused

          expect(@submission).to receive(:touch_context_module)

          @submission.save
        end
      end

      context 'when excused WAS NOT changed' do
        it 'does NOT enqueue a module touch' do
          expect(@submission).not_to receive(:touch_context_module)

          @submission.save
        end
      end
    end

    describe '#touch_context_module' do
      before do
        @student    = student_in_course().user
        @module1    = @course.context_modules.create!(name: "Module 1")
        @assignment = @course.assignments.create!(title: "some assignment")
        @assignment.publish
        @assignment_tag = @module1.add_item(id: @assignment.id, type: 'assignment', title: 'Assignment: requires submission')
        @submission = @assignment.submission_for_student(@student)
      end

      context 'when excused was changed' do
        it 'updates the updated_at timestamp with a touch' do
          expect(@module1.created_at).to be <= Time.zone.now

          new_now = Time.zone.now

          expect {
            @submission.touch_context_module
          }.to change { @module1.reload.updated_at }

          expect(@module1.updated_at).to be >= new_now
        end
      end
    end

    describe '#send_submission_to_pipeline' do
      before do
        allow(SettingsService).to receive(:get_settings).and_return('enable_unit_grade_calculations' => false)
      end

      it 'publishes on create' do
        expect(PipelineService).to receive(:publish).with an_instance_of(Submission)

        submission_model
      end

      it 'publishes on save' do
        @submission = submission_model
        expect(PipelineService).to receive(:publish).with an_instance_of(Submission)

        @submission.save
      end
    end

    describe '#send_unit_grades_to_pipeline' do
      before do
        @env = {
          PIPELINE_ENDPOINT: 'endpoint',
          PIPELINE_USER_NAME: 'name',
          PIPELINE_PASSWORD: 'password',
          SIS_ENROLLMENT_UPDATE_API_KEY: 'junk',
          SIS_ENROLLMENT_UPDATE_ENDPOINT: 'junk',
          SIS_UNIT_GRADE_ENDPOINT_API_KEY: 'hunk',
          SIS_UNIT_GRADE_ENDPOINT: 'junk'
        }

        allow(SettingsService).to receive(:get_settings).and_return({})
        allow(PipelineService::HTTPClient).to receive(:post)

        allow(SettingsService).to receive(:get_settings).and_return('enable_unit_grade_calculations' => true)
        allow(UnitsService::Queries::GetEnrollment).to receive(:query).and_return(@enrollment)
      end

      let(:assignment) {Assignment.create}
      let(:content_tag) {ContentTag.create(content: assignment)}
      let(:context_module) {ContextModule.create(content_tags: [content_tag])}
      let(:course) {Course.create(context_modules: [context_module])}

      it 'wont send if there is no change to the score' do
        skip 'There is no longer PipelineService::Events'

        with_modified_env @env do
          expect(PipelineService::Events::HTTPClient).to_not receive(:post)

          course_with_student_submissions
        end
      end

      context 'setting disabled' do
        it 'wont fire' do
          with_modified_env @env do
            allow(SettingsService).to receive(:get_settings).and_return('enable_unit_grade_calculations' => false)

            # course callback
            expect(PipelineService).to receive(:publish).with(an_instance_of(Course))

            # submission callback
            expect(PipelineService).not_to receive(:publish).with(an_instance_of(PipelineService::Nouns::UnitGrades))

            # will save a submission triggering callback
            course_with_student_submissions(submission_points: 50)
          end
        end
      end
    end
  end
end
