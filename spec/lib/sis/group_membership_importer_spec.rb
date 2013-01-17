require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module SIS
  describe GroupMembershipImporter do
    it 'does not blow up if you hand it integers' do
      group = Group.create!
      group.sis_source_id = "54321"
      group.account = Account.default
      group.save!
      user = user_with_pseudonym
      @pseudonym.sis_user_id = "12345"
      @pseudonym.save!
      GroupMembershipImporter.new(Account.default, {}).process do |importer|
        importer.add_group_membership(12345, 54321, 'accepted')
      end
    end
  end
end
