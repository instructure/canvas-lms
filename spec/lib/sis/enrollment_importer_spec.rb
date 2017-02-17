require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require_dependency "sis/enrollment_importer"

module SIS
  describe EnrollmentImporter do
    let(:user_id) { "5235536377654" }
    let(:course_id) { "82433211" }
    let(:section_id) { "299981672" }

    let(:enrollment) do
      SIS::Models::Enrollment.new(
        course_id: course_id,
        section_id: section_id,
        user_id: user_id,
        role: 'student',
        status: 'active',
        start_date: Time.zone.today,
        end_date: Time.zone.today
      )
    end

    context 'gives a meaningful error message when a user does not exist for an enrollment' do
      let(:messages) { [] }

      before do
        EnrollmentImporter.new(Account.default, {}).process(messages, 2) do |importer|
          importer.add_enrollment(enrollment)
        end
      end

      it { expect(messages.first).to include("User not found for enrollment") }
      it { expect(messages.first).to include("User ID: #{user_id}") }
      it { expect(messages.first).to include("Course ID: #{course_id}") }
      it { expect(messages.first).to include("Section ID: #{section_id}") }
    end

    context 'with a valid user ID but invalid course and section IDs' do
      before(:once) do
        @messages = []
        @student = user_with_pseudonym
        @student.save!
        @pseudonym = @student.pseudonyms.last
        @pseudonym.sis_user_id = @student.id
        @pseudonym.save!
        Account.default.pseudonyms << @pseudonym
        EnrollmentImporter.new(Account.default, {}).process(@messages, 2) do |importer|
          an_enrollment = SIS::Models::Enrollment.new(
            course_id: 1,
            section_id: 2,
            user_id: @student.pseudonyms.last.user_id,
            role: 'student',
            status: 'active',
            start_date: Time.zone.today,
            end_date: Time.zone.today
          )
          importer.add_enrollment(an_enrollment)
        end
      end

      it 'alerts user of nonexistent course/section for user enrollment' do
        expect(@messages.last).to include("Neither course nor section existed for user enrollment ")
      end

      it 'provides a course ID for the offending row' do
        expect(@messages.last).to include('Course ID: 1,')
      end

      it 'provides a section ID for the offending row' do
        expect(@messages.last).to include('Section ID: 2,')
      end

      it 'provides a user ID for the offending row' do
        expect(@messages.last).to include("User ID: #{@student.pseudonyms.last.user_id}")
      end
    end

    it 'should skip touching courses' do
      Timecop.freeze(2.days.ago) do
        @c = course_model(sis_source_id: 'C001')
        u = user_with_managed_pseudonym(sis_user_id: 'U001')
        @e = @c.enroll_user(u)
        @time = @c.updated_at
      end

      Enrollment.skip_touch_callbacks(:course) do
        @e.updated_at = 2.seconds.from_now
        @e.save!
      end
      @c.reload
      expect(@c.updated_at).to eq @time

      @e.updated_at = 5.seconds.from_now
      @e.save!
      @c.reload
      expect(@c.updated_at).not_to eq @time
    end

  end
end
