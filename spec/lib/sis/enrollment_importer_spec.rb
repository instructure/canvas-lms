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

  end
end
