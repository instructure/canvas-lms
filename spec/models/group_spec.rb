#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Group do
  
  before do
    group_model
  end

  context "validation" do
    it "should create a new instance given valid attributes" do
      group_model
    end
  end
  
  it "should have a wiki as the default WikiNamespace wiki" do
    @group.wiki.should eql(WikiNamespace.default_for_context(@group).wiki)
  end
  
  it "should not be public" do
    @group.is_public.should be_false
  end
  
  it "should find all peer groups" do
    context = course_model
    group_category = context.group_categories.create(:name => "worldCup")
    other_category = context.group_categories.create(:name => "other category")
    group1 = Group.create!(:name=>"group1", :group_category => group_category, :context => context)
    group2 = Group.create!(:name=>"group2", :group_category => group_category, :context => context)
    group3 = Group.create!(:name=>"group3", :group_category => group_category, :context => context)
    group4 = Group.create!(:name=>"group4", :group_category => other_category, :context => context)
    group1.peer_groups.length.should == 2
    group1.peer_groups.should be_include(group2)
    group1.peer_groups.should be_include(group3)
    group1.peer_groups.should_not be_include(group1)
    group1.peer_groups.should_not be_include(group4)
  end
  
  it "should not find peer groups for student organized groups" do
    context = course_model
    group_category = GroupCategory.student_organized_for(context)
    group1 = Group.create!(:name=>"group1", :group_category=>group_category, :context => context)
    group2 = Group.create!(:name=>"group2", :group_category=>group_category, :context => context)
    group1.peer_groups.should be_empty
  end
  
  context "atom" do
    it "should have an atom name as it's own name" do
      group_model(:name => 'some unique name')
      @group.to_atom.title.should eql('some unique name')
    end
    
    it "should have a link to itself" do
      link = @group.to_atom.links.first.to_s
      link.should eql("/groups/#{@group.id}")
    end
  end
  
  context "enrollment" do
    it "should be able to add a person to the group" do
      user_model
      pseudonym_model(:user_id => @user.id)
      @group.add_user(@user)
      @group.users.should be_include(@user)
    end
    
    it "shouldn't be able to add a person to the group twice" do
      user_model
      pseudonym_model(:user_id => @user.id)
      @group.add_user(@user)
      @group.users.should be_include(@user)
      @group.users.count.should == 1
      @group.add_user(@user)
      @group.reload
      @group.users.should be_include(@user)
      @group.users.count.should == 1
    end
    
    it "adding a user should remove that user from peer groups" do
      context = course_model
      group_category = context.group_categories.create!(:name => "worldCup")
      group1 = Group.create!(:name=>"group1", :group_category=>group_category, :context => context)
      group2 = Group.create!(:name=>"group2", :group_category=>group_category, :context => context)
      user_model
      pseudonym_model(:user_id => @user.id)
      group1.add_user(@user)
      group1.users.should be_include(@user)
      
      group2.add_user(@user)
      group2.users.should be_include(@user)
      group1.reload
      group1.users.should_not be_include(@user)
    end
    
    # it "should be able to add more than one person at a time" do
      # user_model
      # p1 = pseudonym_model(:user_id => @user.id)
      # u1 = p1.user
      # user_model
      # p2 = pseudonym_model(:user_id => @user.id)
      # u2 = p2.user
      # @group.add_user([u1, u2])
      # @group.users.should be_include(u1)
      # @group.users.should be_include(u2)
    # end
    
    it "should be able to add a person as a user instead as a pseudonym" do
      user_model
      @group.add_user(@user)
      @group.users.should be_include(@user)
    end
    
    it "should be able to add a person with a user id" do
      user_model
      @group.add_user(@user)
      @group.users.should be_include(@user)
    end
    
    # it "should be able to add a person from their communication channel" do
      # user_model
      # communication_channel_model
      # @group.users.should_not be_include(@user)
      # @cc.user.should eql(@user)
      # @group.add_user(@user)
      # @group.users.should be_include(@user)
    # end
    
  end

  it "should grant manage permissions for associated objects to group managers" do
    e = course_with_teacher
    course = e.context
    teacher = e.user
    group = course.groups.create
    course.grants_right?(teacher, nil, :manage_groups).should be_true
    group.grants_right?(teacher, nil, :manage_wiki).should be_true
    group.grants_right?(teacher, nil, :manage_files).should be_true
    WikiNamespace.default_for_context(group).grants_right?(teacher, nil, :update_page).should be_true
    attachment = group.attachments.build
    attachment.grants_right?(teacher, nil, :create).should be_true
  end

  it "should grant read_roster permissions to students that can freely join or request an invitation to the group" do
    course_with_teacher
    student_in_course

    # default join_level == 'invitation_only' and default category is not self-signup
    group = @course.groups.create
    group.grants_right?(@student, nil, :read_roster).should be_false

    # join_level allows requesting group membership
    group = @course.groups.create(:join_level => 'parent_context_request')
    group.grants_right?(@student, nil, :read_roster).should be_true

    # category is self-signup
    category = @course.group_categories.build
    category.configure_self_signup(true, false)
    category.save
    group = @course.groups.create(:group_category => category)
    group.grants_right?(@student, nil, :read_roster).should be_true
  end

  describe "root account" do
    it "should get the root account assigned" do
      e = course_with_teacher
      group = @course.groups.create!
      group.account.should == Account.default
      group.root_account.should == Account.default

      new_root_acct = account_model
      new_sub_acct = new_root_acct.sub_accounts.create!(:name => 'sub acct')
      group.account = new_sub_acct
      group.save!
      group.account.should == new_sub_acct
      group.root_account.should == new_root_acct
    end
  end

  context "auto_accept?" do
    it "should be false unless join level is 'parent_context_auto_join'" do
      course_with_teacher
      student = user_model
      @course.enroll_student(student)
      @course.reload

      group_category = GroupCategory.student_organized_for(@course)
      group = @course.groups.create(:group_category => group_category)
      group.auto_accept?(student).should be_false
    end

    it "should be false unless the group is student organized" do
      course_with_teacher
      student = user_model
      @course.enroll_student(student)
      @course.reload

      group_category = @course.group_categories.create(:name => "random category")
      group = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_auto_join')
      group.auto_accept?(student).should be_false
    end

    it "should be true otherwise" do
      course_with_teacher
      student = user_model
      @course.enroll_student(student)
      @course.reload

      group_category = GroupCategory.student_organized_for(@course)
      group = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_auto_join')
      group.auto_accept?(student).should be_true
    end
  end

  context "allow_join_request?" do
    it "should be false unless join level is 'parent_context_auto_join' or 'parent_context_request'" do
      course_with_teacher
      student = user_model
      @course.enroll_student(student)
      @course.reload

      group_category = GroupCategory.student_organized_for(@course)
      group = @course.groups.create(:group_category => group_category)
      group.allow_join_request?(student).should be_false
    end

    it "should be false unless the group is student organized" do
      course_with_teacher
      student = user_model
      @course.enroll_student(student)
      @course.reload

      group_category = @course.group_categories.create(:name => "random category")
      group = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_auto_join')
      group.allow_join_request?(student).should be_false
    end

    it "should be true otherwise" do
      course_with_teacher
      student = user_model
      @course.enroll_student(student)
      @course.reload

      group_category = GroupCategory.student_organized_for(@course)

      group = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_auto_join')
      group.allow_join_request?(student).should be_true

      group = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_request')
      group.allow_join_request?(student).should be_true
    end
  end

  context "invite_user" do
    it "should auto accept invitations" do
      course_with_student(:active_all => true)

      group_category = GroupCategory.student_organized_for(@course)

      group = @course.groups.create!(:group_category => group_category)
      gm = group.invite_user(@student)
      gm.should be_accepted
    end
  end

  context "request_user" do
    it "should auto accept invitations" do
      course_with_student(:active_all => true)

      group_category = GroupCategory.student_organized_for(@course)

      group = @course.groups.create!(:group_category => group_category, :join_level => 'parent_context_auto_join')
      gm = group.request_user(@student)
      gm.should be_accepted
    end
  end

  it "should default group_category to student organized category on save" do
    course_with_teacher
    group = @course.groups.create
    group.group_category.should == GroupCategory.student_organized_for(@course)

    group_category = @course.group_categories.create(:name => "random category")
    group = @course.groups.create(:group_category => group_category)
    group.group_category.should == group_category
  end

  context "import_from_migration" do
    it "should respect group_category from the hash" do
      course_with_teacher
      group = @course.groups.build
      @course.imported_migration_items = []
      Group.import_from_migration({:group_category => "random category"}, @course, group)
      group.group_category.name.should == "random category"
    end

    it "should default group_category to imported if not in the hash" do
      course_with_teacher
      group = @course.groups.build
      @course.imported_migration_items = []
      Group.import_from_migration({}, @course, group)
      group.group_category.should == GroupCategory.imported_for(@course)
    end
  end

  it "as_json should include group_category" do
    group_category = GroupCategory.create(:name => "Something")
    group = Group.create(:group_category => group_category)
    hash = ActiveSupport::JSON.decode(group.to_json)
    hash["group"]["group_category"].should == "Something"
  end

  it "should maintain the deprecated category attribute" do
    course = course_model
    group = course.groups.create
    default_category = GroupCategory.student_organized_for(course)
    group.read_attribute(:category).should eql(default_category.name)
    group.group_category = group.context.group_categories.create(:name => "my category")
    group.save
    group.reload
    group.read_attribute(:category).should eql("my category")
    group.group_category = nil
    group.save
    group.reload
    group.read_attribute(:category).should eql(default_category.name)
  end

  context "has_common_section?" do
    it "should be false for accounts" do
      account = Account.default
      group = account.groups.create
      group.should_not have_common_section
    end

    it "should not be true if two members don't share a section" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.add_user(user2)
      group.should_not have_common_section
    end

    it "should be true if all members group have a section in common" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section1.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.add_user(user2)
      group.should have_common_section
    end
  end

  context "has_common_section_with_user?" do
    it "should be false for accounts" do
      account = Account.default
      group = account.groups.create
      group.should_not have_common_section_with_user(user_model)
    end

    it "should not be true if the new member does't share a section with an existing member" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.should_not have_common_section_with_user(user2)
    end

    it "should be true if all members group have a section in common with the new user" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section1.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.should have_common_section_with_user(user2)
    end
  end

  context "tabs_available" do
    before do
      course_with_teacher
      @teacher = @user
      @group = group(:group_context => @course)
      @group.users << @student = student_in_course(:course => @course).user
    end

    it "should let members see everything" do
      @group.tabs_available(@student).map{|t|t[:id]}.should eql [
        Group::TAB_HOME,
        Group::TAB_ANNOUNCEMENTS,
        Group::TAB_PAGES,
        Group::TAB_PEOPLE,
        Group::TAB_DISCUSSIONS,
        Group::TAB_CHAT,
        Group::TAB_FILES,
        Group::TAB_CONFERENCES
      ]
    end

    it "should let admins see everything" do
      @group.tabs_available(@teacher).map{|t|t[:id]}.should eql [
        Group::TAB_HOME,
        Group::TAB_ANNOUNCEMENTS,
        Group::TAB_PAGES,
        Group::TAB_PEOPLE,
        Group::TAB_DISCUSSIONS,
        Group::TAB_CHAT,
        Group::TAB_FILES,
        Group::TAB_CONFERENCES
      ]
    end

    it "should not let nobodies see conferences" do
      @group.tabs_available(nil).map{|t|t[:id]}.should_not include Group::TAB_CONFERENCES
    end
  end
  
end
