require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module SIS

  describe GroupMembershipImporter do

    def create_group(opts = {})
      group = Group.create!(opts)
      group.sis_source_id = "54321"
      group.account = Account.default
      group.save!
      group
    end

    def create_user
      user = user_with_pseudonym
      @pseudonym.sis_user_id = "12345"
      @pseudonym.save!
      [user, @pseudonym]
    end

    it 'does not blow up if you hand it integers' do
      create_group
      create_user
      GroupMembershipImporter.new(Account.default, {}).process do |importer|
        importer.add_group_membership(12345, 54321, 'accepted')
      end
    end

    describe 'validation' do
      before do
        course_model
      end

      it "handles validation errors due to lack of section homogeneity" do
        create_user

        group_category = GroupCategory.communities_for(Account.default)
        group_category.self_signup = 'restricted'
        group_category.save!

        create_group(:group_category => group_category)
        
        importer = GroupMembershipImporter.new(Account.default, {})
        lambda do
          importer.process do |importer|
            importer.add_group_membership(12345, group.sis_source_id, 'accepted')
          end
        end.should raise_error(SIS::ImportError)
      end
    end
  end
end
