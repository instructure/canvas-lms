#
# Copyright (C) 2011 - 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GroupsController do
  before :once do
    course_with_teacher(:active_all => true)
    students = create_users_in_course(@course, 3, return_type: :record)
    @student1, @student2, @student3 = students
    @student = @student1
  end

  describe "GET context_index" do
    it "should require authorization" do
      user_session(user) # logged in user without course access
      category1 = @course.group_categories.create(:name => "category 1")
      category2 = @course.group_categories.create(:name => "category 2")
      g1 = @course.groups.create(:name => "some group", :group_category => category1)
      g2 = @course.groups.create(:name => "some other group", :group_category => category1)
      g3 = @course.groups.create(:name => "some third group", :group_category => category2)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@teacher)
      category1 = @course.group_categories.create(:name => "category 1")
      category2 = @course.group_categories.create(:name => "category 2")
      g1 = @course.groups.create(:name => "some group", :group_category => category1)
      g2 = @course.groups.create(:name => "some other group", :group_category => category1)
      g3 = @course.groups.create(:name => "some third group", :group_category => category2)
      get 'index', :course_id => @course.id
      expect(response).to be_success
      expect(assigns[:groups]).not_to be_empty
      expect(assigns[:groups].length).to eql(3)
      expect(assigns[:groups] - [g1,g2,g3]).to be_empty
      expect(assigns[:categories].length).to eql(2)
    end

    it "should return groups in sorted by group category name, then group name for student view" do
      skip "requires pg_collkey on the server" if Group.connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i == 0
      user_session(@student)
      category1 = @course.group_categories.create(:name => "1")
      category2 = @course.group_categories.create(:name => "2")
      category3 = @course.group_categories.create(:name => "11")
      groups = []
      groups << @course.groups.create(:name => "11", :group_category => category1)
      groups << @course.groups.create(:name => "2", :group_category => category1)
      groups << @course.groups.create(:name => "1", :group_category => category1)
      groups << @course.groups.create(:name => "22", :group_category => category2)
      groups << @course.groups.create(:name => "2", :group_category => category2)
      groups << @course.groups.create(:name => "3", :group_category => category2)
      groups << @course.groups.create(:name => "4", :group_category => category3)
      groups << @course.groups.create(:name => "44", :group_category => category3)
      groups << @course.groups.create(:name => "4.5", :group_category => category3)
      groups.each {|g| g.add_user @student, 'accepted' }
      get 'index', :course_id => @course.id, :per_page => 50, :format => 'json'
      expect(response).to be_success
      expect(assigns[:paginated_groups]).not_to be_empty
      expect(assigns[:paginated_groups].length).to eql(9)
      #Check group category ordering
      expect(assigns[:paginated_groups][0].group_category.name).to eql("1")
      expect(assigns[:paginated_groups][1].group_category.name).to eql("1")
      expect(assigns[:paginated_groups][2].group_category.name).to eql("1")
      expect(assigns[:paginated_groups][3].group_category.name).to eql("2")
      expect(assigns[:paginated_groups][4].group_category.name).to eql("2")
      expect(assigns[:paginated_groups][5].group_category.name).to eql("2")
      expect(assigns[:paginated_groups][6].group_category.name).to eql("11")
      expect(assigns[:paginated_groups][7].group_category.name).to eql("11")
      expect(assigns[:paginated_groups][8].group_category.name).to eql("11")
      #Check group name ordering
      expect(assigns[:paginated_groups][0].name).to eql("1")
      expect(assigns[:paginated_groups][1].name).to eql("2")
      expect(assigns[:paginated_groups][2].name).to eql("11")
      expect(assigns[:paginated_groups][3].name).to eql("2")
      expect(assigns[:paginated_groups][4].name).to eql("3")
      expect(assigns[:paginated_groups][5].name).to eql("22")
      expect(assigns[:paginated_groups][6].name).to eql("4")
      expect(assigns[:paginated_groups][7].name).to eql("4.5")
      expect(assigns[:paginated_groups][8].name).to eql("44")
    end
  end

  describe "GET index" do
    it 'should split up current and previous groups' do
      course1 = @course
      group_with_user(group_context: course1, user: @student, active_all: true)
      group1 = @group

      course_with_teacher(active_all: true)
      course2 = @course

      course2.soft_conclude!
      course2.save!

      create_enrollments(course2, [@student])
      group_with_user(group_context: course2, user: @student, active_all: true)
      group2 = @group

      user_session(@student)

      get 'index'
      expect(assigns[:current_groups]).to eq([group1])
      expect(assigns[:previous_groups]).to eq([group2])
    end

    describe 'pagination' do
      before :once do
        group_with_user(:group_context => @course, :user => @student, :active_all => true)
        group_with_user(:group_context => @course, :user => @student, :active_all => true)
      end

      before :each do
        user_session(@student)
      end

      it "should not paginate non-json" do
        get 'index', :per_page => 1
        expect(assigns[:current_groups]).to eq @student.current_groups.by_name
        expect(response.headers['Link']).to be_nil
      end

      it "should paginate json" do
        get 'index', :format => 'json', :per_page => 1
        expect(assigns[:groups]).to eq [@student.current_groups.by_name.first]
        expect(response.headers['Link']).not_to be_nil
      end
    end
  end

  describe "GET show" do
    it "should require authorization" do
      @group = Account.default.groups.create!(:name => "some group")
      get 'show', :id => @group.id
      expect(assigns[:group]).to eql(@group)
      assert_unauthorized
    end

    it "should assign variables" do
      @group = Account.default.groups.create!(:name => "some group")
      @user = user_model
      user_session(@user)
      @group.add_user(@user)
      get 'show', :id => @group.id
      expect(response).to be_success
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:context]).to eql(@group)
      expect(assigns[:stream_items]).to eql([])
    end

    it "should allow user to join self-signup groups" do
      user_session(@student)
      category1 = @course.group_categories.create!(:name => "category 1")
      category1.configure_self_signup(true, false)
      category1.save!
      g1 = @course.groups.create!(:name => "some group", :group_category => category1)

      get 'show', :course_id => @course.id, :id => g1.id, :join => 1
      g1.reload
      expect(g1.users.map(&:id)).to include @student.id
    end

    it "should allow user to leave self-signup groups" do
      user_session(@student)
      category1 = @course.group_categories.create!(:name => "category 1")
      category1.configure_self_signup(true, false)
      category1.save!
      g1 = @course.groups.create!(:name => "some group", :group_category => category1)
      g1.add_user(@student)

      get 'show', :course_id => @course.id, :id => g1.id, :leave => 1
      g1.reload
      expect(g1.users.map(&:id)).not_to include @student.id
    end

    it "should allow user to join student organized groups" do
      user_session(@student)
      category1 = GroupCategory.student_organized_for(@course)
      g1 = @course.groups.create!(:name => "some group", :group_category => category1, :join_level => "parent_context_auto_join")

      get 'show', :course_id => @course.id, :id => g1.id, :join => 1
      g1.reload
      expect(g1.users.map(&:id)).to include @student.id
    end

    it "should allow user to leave student organized groups" do
      user_session(@student)
      category1 = @course.group_categories.create!(:name => "category 1", :role => "student_organized")
      g1 = @course.groups.create!(:name => "some group", :group_category => category1)
      g1.add_user(@student)

      get 'show', :course_id => @course.id, :id => g1.id, :leave => 1
      g1.reload
      expect(g1.users.map(&:id)).not_to include @student.id
    end
  end

  describe "GET new" do
    it "should require authorization" do
      @group = @course.groups.create!(:name => "some group")
      get 'new', :course_id => @course.id
      assert_unauthorized
    end
  end

  describe "POST add_user" do
    it "should require authorization" do
      @group = Account.default.groups.create!(:name => "some group")
      post 'add_user', :group_id => @group.id
      assert_unauthorized
    end

    it "should add user" do
      user_session(@teacher)
      @group = @course.groups.create!(:name => "PG 1", :group_category => @category)
      @user = user(:active_all => true)
      post 'add_user', :group_id => @group.id, :user_id => @user.id
      expect(response).to be_success
      expect(assigns[:membership]).not_to be_nil
      expect(assigns[:membership].user).to eql(@user)
    end

    it "should check user section in restricted self-signup category" do
      user_session(@teacher)
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      group_category = @course.group_categories.build(:name => "My Category")
      group_category.configure_self_signup(true, true)
      group_category.save
      group = group_category.groups.create(:context => @course)
      group.add_user(user1)

      post 'add_user', :group_id => group.id, :user_id => user2.id
      expect(response).not_to be_success
      expect(assigns[:membership]).not_to be_nil
      expect(assigns[:membership].user).to eql(user2)
      expect(assigns[:membership].errors[:user_id]).not_to be_nil
    end
  end

  describe "DELETE remove_user" do
    it "should require authorization" do
      @group = Account.default.groups.create!(:name => "some group")
      @user = user(:active_all => true)
      @group.add_user(@user)
      delete 'remove_user', :group_id => @group.id, :user_id => @user.id, :id => @user.id
      assert_unauthorized
    end

    it "should remove user" do
      user_session(@teacher)
      @group = @course.groups.create!(:name => "PG 1", :group_category => @category)
      @group.add_user(@user)
      delete 'remove_user', :group_id => @group.id, :user_id => @user.id, :id => @user.id
      expect(response).to be_success
      @group.reload
      expect(@group.users).to be_empty
    end
  end

  describe "POST create" do
    it "should require authorization" do
      post 'create', :course_id => @course.id, :group => {:name => "some group"}
      assert_unauthorized
    end

    it "should create new group" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :group => {:name => "some group"}
      expect(response).to be_redirect
      expect(assigns[:group]).not_to be_nil
      expect(assigns[:group].name).to eql("some group")
    end

    it "should honor group[group_category_id] when permitted" do
      user_session(@teacher)
      group_category = @course.group_categories.create(:name => 'some category')
      post 'create', :course_id => @course.id, :group => {:name => "some group", :group_category_id => group_category.id}
      expect(response).to be_redirect
      expect(assigns[:group]).not_to be_nil
      expect(assigns[:group].group_category).to eq group_category
    end

    it "should not honor group[group_category_id] when not permitted" do
      user_session(@student)
      group_category = @course.group_categories.create(:name => 'some category')
      post 'create', :course_id => @course.id, :group => {:name => "some group", :group_category_id => group_category.id}
      expect(response).to be_redirect
      expect(assigns[:group]).not_to be_nil
      expect(assigns[:group].group_category).to eq GroupCategory.student_organized_for(@course)
    end

    it "should fail when group[group_category_id] would be honored but doesn't exist" do
      user_session(@student)
      group_category = @course.group_categories.create(:name => 'some category')
      post 'create', :course_id => @course.id, :group => {:name => "some group", :group_category_id => 11235}
      expect(response).not_to be_success
    end
    
    describe "quota" do
      before do
        Setting.set('group_default_quota', 11.megabytes)
      end
      
      context "teacher" do
        before do
          user_session(@teacher)
        end
        
        it "should ignore the storage_quota_mb parameter" do
          post 'create', :course_id => @course.id, :group => {:name => "a group", :storage_quota_mb => 22}
          expect(assigns[:group].storage_quota_mb).to eq 11
        end
      end
      
      context "account admin" do
        before do
          account_admin_user
          user_session(@admin)
        end
        
        it "should set the storage_quota_mb parameter" do
          post 'create', :course_id => @course.id, :group => {:name => "a group", :storage_quota_mb => 22}
          expect(assigns[:group].storage_quota_mb).to eq 22
        end
      end
    end
  end

  describe "PUT update" do
    it "should require authorization" do
      @group = @course.groups.create!(:name => "some group")
      put 'update', :course_id => @course.id, :id => @group.id, :group => {:name => "new name"}
      assert_unauthorized
    end

    it "should update group" do
      user_session(@teacher)
      @group = @course.groups.create!(:name => "some group")
      put 'update', :course_id => @course.id, :id => @group.id, :group => {:name => "new name"}
      expect(response).to be_redirect
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group].name).to eql("new name")
    end

    it "should honor group[group_category_id]" do
      user_session(@teacher)
      group_category = @course.group_categories.create(:name => 'some category')
      @group = @course.groups.create!(:name => "some group")
      put 'update', :course_id => @course.id, :id => @group.id, :group => {:group_category_id => group_category.id}
      expect(response).to be_redirect
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group].group_category).to eq group_category
    end

    it "should fail when group[group_category_id] doesn't exist" do
      user_session(@teacher)
      group_category = @course.group_categories.create(:name => 'some category')
      @group = @course.groups.create!(:name => "some group", :group_category => group_category)
      put 'update', :course_id => @course.id, :id => @group.id, :group => {:group_category_id => 11235}
      expect(response).not_to be_success
    end
    
    describe "quota" do
      before :once do
        @group = @course.groups.build(:name => "teh gruop")
        @group.storage_quota_mb = 11
        @group.save!
      end
      
      context "teacher" do
        before do
          user_session(@teacher)
        end
        
        it "should ignore the quota parameter" do
          put 'update', :course_id => @course.id, :id => @group.id, :group => {:name => 'the group', :storage_quota_mb => 22}
          @group.reload
          expect(@group.name).to eq 'the group'
          expect(@group.storage_quota_mb).to eq 11
        end
      end
      
      context "account admin" do
        before do
          account_admin_user
          user_session(@admin)
        end
        
        it "should update group quota" do
          put 'update', :course_id => @course.id, :id => @group.id, :group => {:name => 'the group', :storage_quota_mb => 22}
          @group.reload
          expect(@group.name).to eq 'the group'
          expect(@group.storage_quota_mb).to eq 22
        end
      end
    end
  end
  
  describe "DELETE destroy" do
    it "should require authorization" do
      @group = @course.groups.create!(:name => "some group")
      delete 'destroy', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it "should delete group" do
      user_session(@teacher)
      @group = @course.groups.create!(:name => "some group")
      delete 'destroy', :course_id => @course.id, :id => @group.id
      expect(assigns[:group]).to eql(@group)
      expect(assigns[:group]).not_to be_frozen
      expect(assigns[:group]).to be_deleted
      expect(@course.groups).to be_include(@group)
      expect(@course.groups.active).not_to be_include(@group)
    end
  end

  describe "GET 'unassigned_members'" do
    it "should include all users if the category is student organized" do
      user_session(@teacher)
      u1 = @student1
      u2 = @student2
      u3 = @student3

      group = @course.groups.create(:name => "Group 1", :group_category => GroupCategory.student_organized_for(@course))
      group.add_user(u1)
      group.add_user(u2)

      get 'unassigned_members', :course_id => @course.id, :category_id => group.group_category.id
      expect(response).to be_success
      data = json_parse
      expect(data).not_to be_nil
      expect(data['users'].map{ |u| u['user_id'] }.sort).
        to eq [u1, u2, u3].map{ |u| u.id }.sort
    end

    it "should include only users not in a group in the category otherwise" do
      user_session(@teacher)
      u1 = @student1
      u2 = @student2
      u3 = @student3

      group_category1 = @course.group_categories.create(:name => "Group Category 1")
      group1 = @course.groups.create(:name => "Group 1", :group_category => group_category1)
      group1.add_user(u1)

      group_category2 = @course.group_categories.create(:name => "Group Category 2")
      group2 = @course.groups.create(:name => "Group 1", :group_category => group_category2)
      group2.add_user(u2)

      group_category3 = @course.group_categories.create(:name => "Group Category 3")
      group3 = @course.groups.create(:name => "Group 1", :group_category => group_category3)
      group3.add_user(u2)
      group3.add_user(u3)

      get 'unassigned_members', :course_id => @course.id, :category_id => group1.group_category.id
      expect(response).to be_success
      data = json_parse
      expect(data).not_to be_nil
      expect(data['users'].map{ |u| u['user_id'] }.sort).
        to eq [u2, u3].map{ |u| u.id }.sort

      get 'unassigned_members', :course_id => @course.id, :category_id => group2.group_category.id
      expect(response).to be_success
      data = json_parse
      expect(data).not_to be_nil
      expect(data['users'].map{ |u| u['user_id'] }.sort).
        to eq [u1, u3].map{ |u| u.id }.sort

      get 'unassigned_members', :course_id => @course.id, :category_id => group3.group_category.id
      expect(response).to be_success
      data = json_parse
      expect(data).not_to be_nil
      expect(data['users'].map{ |u| u['user_id'] }).to eq [ u1.id ]
    end

    it "should include the users' sections when available" do
      user_session(@teacher)
      u1 = @student1
      u2 = @student2

      group = @course.groups.create(:name => "Group 1", :group_category => GroupCategory.student_organized_for(@course))
      group.add_user(u1)

      get 'unassigned_members', :course_id => @course.id, :category_id => group.group_category.id
      data = json_parse
      expect(data['users'].first['sections'].first['section_id']).to eq @course.default_section.id
      expect(data['users'].first['sections'].first['section_code']).to eq @course.default_section.section_code
    end
  end

  describe "GET 'context_group_members'" do
    it "should include the users' sections when available" do
      user_session(@teacher)
      u1 = @student1
      group = @course.groups.create(:name => "Group 1", :group_category => GroupCategory.student_organized_for(@course))
      group.add_user(u1)

      get 'context_group_members', :group_id => group.id
      data = json_parse
      expect(data.first['sections'].first['section_id']).to eq @course.default_section.id
      expect(data.first['sections'].first['section_code']).to eq @course.default_section.section_code
    end

    it "should require :read_roster permission" do
      u1 = @student1
      u2 = @student2
      group = @course.groups.create(:name => "Group 1")
      group.add_user(u1)

      # u1 in the group has :read_roster permission
      user_session(u1)
      get 'context_group_members', :group_id => group.id
      expect(response).to be_success

      # u2 outside the group doesn't have :read_roster permission, since the
      # group isn't self-signup and is invitation only (clear controller
      # context permission cache, though)
      controller.instance_variable_set(:@context_all_permissions, nil)
      user_session(u2)
      get 'context_group_members', :group_id => group.id
      expect(response).not_to be_success
    end
  end

  describe "GET 'public_feed.atom'" do
    before :once do
      group_with_user(:active_all => true)
      @group.discussion_topics.create!(:title => "hi", :message => "intros", :user => @user)
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @group.feed_code + 'x'
      expect(assigns[:problem]).to match /The verification code is invalid/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @group.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.links.first.rel).to match(/self/)
      expect(feed.links.first.href).to match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @group.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all?{|e| e.authors.present?}).to be_truthy
    end
  end

  describe "GET 'accept_invitation'" do
    before :once do
      @communities = GroupCategory.communities_for(Account.default)
      group_model(:group_category => @communities)
      user(:active_user => true)
      @membership = @group.add_user(@user, 'invited', false)
    end

    before :each do
      user_session(@user)
    end

    it "should successfully create invitations" do
      get 'accept_invitation', :group_id => @group.id, :uuid => @membership.uuid
      @group.reload
      expect(@group.has_member?(@user)).to be_truthy
      expect(@group.group_memberships.where(:workflow_state => "invited").count).to eq 0
    end

    it "should reject an invalid invitation uuid" do
      get 'accept_invitation', :group_id => @group.id, :uuid => @membership.uuid + "x"
      @group.reload
      expect(@group.has_member?(@user)).to be_falsey
      expect(@group.group_memberships.where(:workflow_state => "invited").count).to eq 1
    end
  end
end
