require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module SIS
  describe EnrollmentImporter do

    it 'does not break postgres if I give it integers' do
      messages = []
      EnrollmentImporter.new(Account.default, {}).process(messages, 2) do |importer|
        enrollment = SIS::Models::Enrollment.new()
        enrollment.course_id = 1
        enrollment.section_id = 2
        enrollment.user_id = 3
        enrollment.role = 'student'
        enrollment.status = 'active'
        enrollment.start_date = Time.zone.today
        enrollment.end_date = Time.zone.today
        importer.add_enrollment(enrollment)
      end
      expect(messages).not_to be_empty
    end

    it 'should skip touching courses' do
      Timecop.freeze(2.days.ago) do
        @c = course_model(sis_source_id: 'C001')
        u = user_with_managed_pseudonym(sis_user_id: 'U001')
        @e = @c.enroll_user(u)
        @time = @c.updated_at
      end

      # this is the new way that the callback is being suspended
      Enrollment.suspend_callbacks("(belongs_to_touch_after_save_or_destroy_for_course)") do
        @e.save!
      end
      @c.reload
      expect(@c.updated_at).to eq @time

      # this is the old way that the callback was being suspended
      Enrollment.suspend_callbacks(:belongs_to_touch_after_save_or_destroy_for_course) do
        @e.save!
      end
      @c.reload
      expect(@c.updated_at).not_to eq @time
    end

  end
end
