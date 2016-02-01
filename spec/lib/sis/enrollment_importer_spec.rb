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
