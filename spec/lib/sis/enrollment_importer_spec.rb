require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module SIS
  describe EnrollmentImporter do

    it 'does not break postgres if I give it integers' do
      messages = []
      EnrollmentImporter.new(Account.default, {}).process(messages, 2) do |importer|
        importer.add_enrollment(1, 2, 3, 'student', 'active', Date.today, Date.today)
      end
      expect(messages).not_to be_empty
    end

  end
end
