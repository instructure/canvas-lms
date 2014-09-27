#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

describe "Groups API", type: :request do
  def group_json(group, opts = {})
    opts[:is_admin] ||= false
    opts[:include_users] ||= false
    json = {
      'id' => group.id,
      'name' => group.name,
      'description' => group.description,
      'is_public' => group.is_public,
      'join_level' => group.join_level,
      'members_count' => group.members_count,
      'max_membership' => group.max_membership,
      'avatar_url' => group.avatar_attachment && "http://www.example.com/images/thumbnails/#{group.avatar_attachment.id}/#{group.avatar_attachment.uuid}",
      'context_type' => group.context_type,
      "#{group.context_type.downcase}_id" => group.context_id,
      'role' => group.group_category.role,
      'group_category_id' => group.group_category_id,
      'storage_quota_mb' => group.storage_quota_mb,
      'leader' => group.leader
    }
    if opts[:include_users]
      json['users'] = users_json(group.users)
    end
    if group.context_type == 'Account' && opts[:is_admin]
      json['sis_import_id'] = group.sis_batch_id
      json['sis_group_id'] = group.sis_source_id
    end
    json
  end

  def users_json(users)
    users.map { |user| user_json(user) }
  end

  def user_json(user)
    {
      'id' => user.id,
      'name' => user.name,
      'sortable_name' => user.sortable_name,
      'short_name' => user.short_name
    }
  end

  def membership_json(membership, is_admin = false)
    json = {
      'id' => membership.id,
      'group_id' => membership.group_id,
      'user_id' => membership.user_id,
      'workflow_state' => membership.workflow_state,
      'moderator' => membership.moderator,
    }
    json['sis_import_id'] = membership.sis_batch_id if membership.group.context_type == 'Account' && is_admin
    json
  end

  before :once do
    @moderator = user_model
    @member = user_with_pseudonym

    @communities = GroupCategory.communities_for(Account.default)
    @community = group_model(:name => "Algebra Teachers", :group_category => @communities, :context => Account.default)
    @community.add_user(@member, 'accepted', false)
    @community.add_user(@moderator, 'accepted', true)
    @community_path = "/api/v1/groups/#{@community.id}"
    @category_path_options = { :controller => "groups", :format => "json" }
    @context = @community
  end

  it "should allow listing all a user's groups" do
    course_with_student(:user => @member)
    @group = @course.groups.create!(:name => "My Group")
    @group.add_user(@member, 'accepted', true)

    @user = @member
    json = api_call(:get, "/api/v1/users/self/groups", @category_path_options.merge(:action => "index"))
    json.should == [group_json(@community), group_json(@group)]
    links = response.headers['Link'].split(",")
    links.all?{ |l| l =~ /api\/v1\/users\/self\/groups/ }.should be_true
  end

  it "should allow listing all a user's group in a given context_type" do
    @account = Account.default
    course_with_student(:user => @member)
    @group = @course.groups.create!(:name => "My Group")
    @group.add_user(@member, 'accepted', true)

    @user = @member
    json = api_call(:get, "/api/v1/users/self/groups?context_type=Course", @category_path_options.merge(:action => "index", :context_type => 'Course'))
    json.should == [group_json(@group)]

    json = api_call(:get, "/api/v1/users/self/groups?context_type=Account", @category_path_options.merge(:action => "index", :context_type => 'Account'))
    json.should == [group_json(@community)]
  end

  it "should allow listing all of a course's groups" do
    course_with_teacher(:active_all => true)
    @group = @course.groups.create!(:name => 'New group')

    json = api_call(:get, "/api/v1/courses/#{@course.to_param}/groups.json",
                    @category_path_options.merge(:action => 'context_index',
                                                  :course_id => @course.to_param))
    json.count.should == 1
    json.first['id'].should == @group.id
  end

  it "should allow listing all of an account's groups for account admins" do
    @account = Account.default
    sis_batch = @account.sis_batches.create
    SisBatch.where(id: sis_batch).update_all(workflow_state: 'imported')
    @community.sis_source_id = 'sis'
    @community.sis_batch_id = sis_batch.id
    @community.save!
    account_admin_user(:account => @account)

    json = api_call(:get, "/api/v1/accounts/#{@account.to_param}/groups.json",
                    @category_path_options.merge(:action => 'context_index',
                                                  :account_id => @account.to_param))
    json.count.should == 1
    json.first.should == group_json(@community, :is_admin =>true)

    json.first['id'].should == @community.id
    json.first['sis_group_id'].should == 'sis'
    json.first['sis_import_id'].should == sis_batch.id
  end

  it "should not allow non-admins to view an account's groups" do
    @account = Account.default
    raw_api_call(:get, "/api/v1/accounts/#{@account.to_param}/groups.json",
                    @category_path_options.merge(:action => 'context_index',
                                                  :account_id => @account.to_param))
    response.code.should == '401'
  end

  it "should show students all groups" do
    course_with_student(:active_all => true)
    @group_1 = @course.groups.create!(:name => 'Group 1')
    @group_2 = @course.groups.create!(:name => 'Group 2')
    @group_1.add_user(@user, 'accepted', false)

    json = api_call(:get, "/api/v1/courses/#{@course.to_param}/groups.json",
                    @category_path_options.merge(:action => 'context_index',
                                                  :course_id => @course.to_param))
    json.count.should == 2
    json.first['id'].should == @group_1.id
  end

  it "should allow a member to retrieve the group" do
    @user = @member
    json = api_call(:get, @community_path, @category_path_options.merge(:group_id => @community.to_param, :action => "show"))
    json.should == group_json(@community)
  end

  it "should include the group category" do
    @user = @member
    json = api_call(:get, "#{@community_path}.json?include[]=group_category", @category_path_options.merge(:group_id => @community.to_param, :action => "show", :include => [ "group_category" ]))
    json.has_key?("group_category").should be_true
  end

  it 'should include permissions' do
    # Make sure it only returns permissions when asked
    json = api_call(:get, @community_path, @category_path_options.merge(:group_id => @community.to_param, :action => "show", :format => 'json'))
    json.has_key?("permissions").should be_false

    # When its asked to return permissions make sure they are there
    json = api_call(:get, "#{@community_path}.json?include[]=permissions", @category_path_options.merge(:group_id => @community.to_param, :action => "show", :format => 'json', :include => [ "permissions" ]))
    json.has_key?("permissions").should be_true
  end

  it 'should include permission create_discussion_topic' do
    json = api_call(:get, "#{@community_path}.json?include[]=permissions", @category_path_options.merge(:group_id => @community.to_param, :action => "show", :format => 'json', :include => [ "permissions" ]))

    json.has_key?("permissions").should be_true
    json["permissions"].has_key?("create_discussion_topic").should be_true
  end

  it "should allow searching by SIS ID" do
    @community.update_attribute(:sis_source_id, 'abc')
    json = api_call(:get, "/api/v1/groups/sis_group_id:abc", @category_path_options.merge(:group_id => 'sis_group_id:abc', :action => "show"))
    json.should == group_json(@community)
  end

  it "should allow anyone to create a new community" do
    user_model
    json = api_call(:post, "/api/v1/groups", @category_path_options.merge(:action => "create"), {
      'name'=> "History Teachers",
      'description' => "Because history is awesome!",
      'is_public'=> false,
      'join_level'=> "parent_context_request",
    })
    @community2 = Group.order(:id).last
    @community2.group_category.should be_communities
    json.should == group_json(@community2, :include_users => true)
  end

  it "should allow a teacher to create a group in a course" do
    course_with_teacher
    @user = @teacher
    project_groups = @course.group_categories.build
    project_groups.name = "Course Project Groups"
    project_groups.save
    json = api_call(:post, "/api/v1/group_categories/#{project_groups.id}/groups", @category_path_options.merge(:action => "create", :group_category_id =>project_groups.to_param))
    project_groups.groups.active.count.should == 1
  end

  it "should not allow a student to create a group in a course" do
    course_with_student
    @user = @student
    project_groups = @course.group_categories.build
    project_groups.name = "Course Project Groups"
    project_groups.save
    raw_api_call(:post, "/api/v1/group_categories/#{project_groups.id}/groups", @category_path_options.merge(:action => "create", :group_category_id =>project_groups.to_param))
    response.code.should == '401'
  end

  it "should allow an admin to create a group in a account" do
    @account = Account.default
    account_admin_user(:account => @account)
    project_groups = @account.group_categories.build
    project_groups.name = "test group category"
    project_groups.save
    api_call(:post, "/api/v1/group_categories/#{project_groups.id}/groups", @category_path_options.merge(:action => "create", :group_category_id =>project_groups.to_param))
    project_groups.groups.active.count.should == 1
  end

  it "should not allow a non-admin to create a group in a account" do
    @account = Account.default
    project_groups = @account.group_categories.build
    project_groups.name = "test group category"
    project_groups.save
    raw_api_call(:post, "/api/v1/group_categories/#{project_groups.id}/groups", @category_path_options.merge(:action => "create", :group_category_id =>project_groups.to_param))
    response.code.should == '401'
  end


  it "should allow a moderator to edit a group" do
    avatar = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @community)
    @user = @moderator
    new_attrs = {
      'name' => "Algebra II Teachers",
      'description' => "Math rocks!",
      'is_public' => true,
      'join_level' => "parent_context_auto_join",
      'avatar_id' => avatar.id,
    }
    json = api_call(:put, @community_path, @category_path_options.merge(:group_id => @community.to_param, :action => "update"), new_attrs)
    @community.reload
    @community.name.should == "Algebra II Teachers"
    @community.description.should == "Math rocks!"
    @community.is_public.should == true
    @community.join_level.should == "parent_context_auto_join"
    @community.avatar_attachment.should == avatar
    json.should == group_json(@community)
  end

  it "should only allow updating a group from private to public" do
    @user = @moderator
    new_attrs = {
      'is_public' => true,
    }
    json = api_call(:put, @community_path, @category_path_options.merge(:group_id => @community.to_param, :action => "update"), new_attrs)
    @community.reload
    @community.is_public.should == true

    new_attrs = {
      'is_public' => false,
    }
    json = api_call(:put, @community_path, @category_path_options.merge(:group_id => @community.to_param, :action => "update"), new_attrs, {}, :expected_status => 400)
    @community.reload
    @community.is_public.should == true
  end

  it "should not allow a member to edit a group" do
    @user = @member
    new_attrs = {
      'name'=> "Algebra II Teachers",
      'is_public'=> true,
      'join_level'=> "parent_context_auto_join",
    }
    json = api_call(:put, @community_path, @category_path_options.merge(:group_id => @community.to_param, :action => "update"), new_attrs, {}, :expected_status => 401)
  end

  it "should allow a moderator to delete a group" do
    @user = @moderator
    json = api_call(:delete, @community_path, @category_path_options.merge(:group_id => @community.to_param, :action => "destroy"))
    @community.reload.workflow_state.should == 'deleted'
  end

  it "should not allow a member to delete a group" do
    @user = @member
    json = api_call(:delete, @community_path, @category_path_options.merge(:group_id => @community.to_param, :action => "destroy"), {}, {}, :expected_status => 401)
  end

  describe "quota" do
    before :once do
      @account = Account.default
      Setting.set('group_default_quota', 11.megabytes)
    end

    context "with manage_storage_quotas permission" do
      before :once do
        account_admin_user :account => @account
      end

      it "should set the quota on create" do
        json = api_call(:post, '/api/v1/groups?name=TehGroup&storage_quota_mb=22',
                 { :controller => "groups", :action => 'create', :format => "json", :name => 'TehGroup', :storage_quota_mb => '22' })
        group = @account.groups.find(json['id'])
        group.storage_quota_mb.should == 22
      end

      it "should set the quota on update" do
        group = @account.groups.create! :name => 'TehGroup'
        api_call(:put, "/api/v1/groups/#{group.id}?storage_quota_mb=22",
                 { :controller => 'groups', :action => 'update', :group_id => group.id.to_s, :format => 'json', :storage_quota_mb => '22' })
        group.reload.storage_quota_mb.should == 22
      end
    end

    context "without manage_storage_quotas permission" do
      before :once do
        account_admin_user_with_role_changes(:role_changes => {:manage_storage_quotas => false})
      end

      it "should ignore the quota on create" do
        json = api_call(:post, '/api/v1/groups?storage_quota_mb=22',
                        { :controller => 'groups', :action => 'create', :format => 'json', :storage_quota_mb => '22' })
        group = @account.groups.find(json['id'])
        group.storage_quota_mb.should == 11
      end

      it "should ignore the quota on update" do
        group = @account.groups.create! :name => 'TehGroup'
        api_call(:put, "/api/v1/groups/#{group.id}?storage_quota_mb=22&name=TheGruop",
                 { :controller => 'groups', :action => 'update', :format => 'json', :group_id => group.id.to_s, :name => 'TheGruop', :storage_quota_mb => '22' })
        group.reload
        group.name.should == 'TheGruop'
        group.storage_quota_mb.should == 11
      end
    end
  end

  context "memberships" do
    before do
      @memberships_path = "#{@community_path}/memberships"
      @alternate_memberships_path = "#{@community_path}/users"
      @memberships_path_options = { :controller => "group_memberships", :format => "json" }
    end

    it "should allow listing the group memberships" do
      @user = @moderator
      json = api_call(:get, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "index"))
      json.sort_by{|a| a['id'] }.should == [membership_json(@community.has_member?(@member)), membership_json(@community.has_member?(@moderator))]
    end

    it "should allow filtering to a certain membership state" do
      user_model
      @community.add_user(@user, 'invited')
      @user = @moderator
      json = api_call(:get, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "index"), {
        :filter_states => ["invited"]
      })
      json.count.should == 1
      json.first.should == membership_json(@community.group_memberships.where(:workflow_state => 'invited').first)
    end

    it "should allow someone to request to join a group" do
      @user = user_model
      @community.join_level = "parent_context_request"
      @community.save!
      json = api_call(:post, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "create"), {
        :user_id => @user.id
      })
      @membership = GroupMembership.where(:user_id => @user, :group_id => @community).first
      @membership.workflow_state.should == "requested"
      json.should == membership_json(@membership).merge("just_created" => true)
    end

    it "should allow someone to join a group" do
      @user = user_model
      @community.join_level = "parent_context_auto_join"
      @community.save!
      json = api_call(:post, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "create"), {
        :user_id => @user.id
      })
      @membership = GroupMembership.where(:user_id => @user, :group_id => @community).first
      @membership.workflow_state.should == "accepted"
      json.should == membership_json(@membership).merge("just_created" => true)
    end

    it "should not allow a moderator to add someone directly to the group" do
      @new_user = user_model
      @user = @moderator
      @community.join_level = "parent_context_auto_join"
      @community.save!
      api_call(:post, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "create"), {
        :user_id => @new_user.id
      }, {}, :expected_status => 401)
    end

    it "should allow accepting a join request by a moderator" do
      @user = user_model
      @community.join_level = "parent_context_request"
      @community.save!
      @membership = @community.add_user(@user)
      @user = @moderator
      json = api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :workflow_state => "accepted"
      })
      @membership.reload.should be_active
      json.should == membership_json(@membership)
    end

    it "should allow accepting a join request by a moderator using users/:user_id endpoint" do
      @user = user_model
      user_id = @user.id
      @community.join_level = "parent_context_request"
      @community.save!
      @membership = @community.add_user(@user)
      @user = @moderator
      json = api_call(:put, "#{@alternate_memberships_path}/#{user_id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => user_id.to_param, :action => "update"), {
          :workflow_state => "accepted"
      })
      @membership.reload.should be_active
      json.should == membership_json(@membership)
    end

    it "should not allow other workflow_state modifications" do
      @user = @moderator
      @membership = @community.group_memberships.where(user_id: @member).first
      json = api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :workflow_state => "requested"
      })
      @membership.reload.should be_active

      json = api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :workflow_state => "invited"
      })
      @membership.reload.should be_active

      json = api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :workflow_state => "deleted"
      })
      @membership.reload.should be_active
    end

    it "should not allow other workflow_state modifications using users/:user_id endpoint" do
      @user = @moderator
      @membership = @community.group_memberships.where(user_id: @member).first
      json = api_call(:put, "#{@alternate_memberships_path}/#{@user.id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => @user.to_param, :action => "update"), {
          :workflow_state => "requested"
      })
      @membership.reload.should be_active

      json = api_call(:put, "#{@alternate_memberships_path}/#{@user.id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => @user.to_param, :action => "update"), {
          :workflow_state => "invited"
      })
      @membership.reload.should be_active

      json = api_call(:put, "#{@alternate_memberships_path}/#{@user.id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => @user.to_param, :action => "update"), {
          :workflow_state => "deleted"
      })
      @membership.reload.should be_active
    end

    it "should not allow a member to accept join requests" do
      @user = user_model
      @community.join_level = "parent_context_request"
      @community.save!
      @membership = @community.add_user(@user)
      @user = @member
      api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :workflow_state => "accepted"
      }, {}, :expected_status => 401)
      @membership.reload.should be_requested
    end

    it "should not allow a member to accept join requests using users/:user_id endpoint" do
      @user = user_model
      @community.join_level = "parent_context_request"
      @community.save!
      @membership = @community.add_user(@user)
      @user = @member
      api_call(:put, "#{@alternate_memberships_path}/#{@user.id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => @user.to_param, :action => "update"), {
          :workflow_state => "accepted"
      }, {}, :expected_status => 401)
      @membership.reload.should be_requested
    end

    it "should allow changing moderator privileges" do
      @user = @moderator
      @membership = @community.group_memberships.where(user_id: @member).first
      api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :moderator => true
      })
      @membership.reload.moderator.should be_true

      api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :moderator => false
      })
      @membership.reload.moderator.should be_false
    end

    it "should allow changing moderator privileges using users/:user_id endpoint" do
      @user = @moderator
      @membership = @community.group_memberships.where(user_id: @member).first
      api_call(:put, "#{@alternate_memberships_path}/#{@member.id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => @member.to_param, :action => "update"), {
          :moderator => true
      })
      @membership.reload.moderator.should be_true

      api_call(:put, "#{@alternate_memberships_path}/#{@member.id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => @member.to_param, :action => "update"), {
          :moderator => false
      })
      @membership.reload.moderator.should be_false
    end

    it "should not allow a member to change moderator privileges" do
      @user = @member
      @membership = @community.group_memberships.where(user_id: @moderator).first
      api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :moderator => false
      }, {}, :expected_status => 401)
      @membership.reload.moderator.should be_true
    end

    it "should not allow a member to change moderator privileges using users/:user_id endpoint" do
      @user = @member
      @membership = @community.group_memberships.where(user_id: @moderator).first
      api_call(:put, "#{@alternate_memberships_path}/#{@user.id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => @user.to_param, :action => "update"), {
          :moderator => false
      }, {}, :expected_status => 401)
      @membership.reload.moderator.should be_true
    end

    it "should allow someone to leave a group" do
      @user = @member
      @gm = @community.group_memberships.where(:user_id => @user).first
      api_call(:delete, "#{@memberships_path}/#{@gm.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @gm.to_param, :action => "destroy"))
      @membership = GroupMembership.where(:user_id => @user, :group_id => @community).first
      @membership.workflow_state.should == "deleted"
    end

    it "should allow someone to leave a group using users/:user_id endpoint" do
      @user = @member
      @gm = @community.group_memberships.where(:user_id => @user).first
      api_call(:delete, "#{@alternate_memberships_path}/#{@user.id}", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => @user.to_param, :action => "destroy"))
      @membership = GroupMembership.where(:user_id => @user, :group_id => @community).first
      @membership.workflow_state.should == "deleted"
    end

    it "should allow leaving a group using 'self'" do
      @user = @member
      api_call(:delete, "#{@memberships_path}/self", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => 'self', :action => "destroy"))
      @membership = GroupMembership.where(:user_id => @user, :group_id => @community).first
      @membership.workflow_state.should == "deleted"
    end

    it "should allow leaving a group using 'self' using users/:user_id endpoint" do
      @user = @member
      api_call(:delete, "#{@alternate_memberships_path}/self", @memberships_path_options.merge(:group_id => @community.to_param, :user_id => 'self', :action => "destroy"))
      @membership = GroupMembership.where(:user_id => @user, :group_id => @community).first
      @membership.workflow_state.should == "deleted"
    end

    it "should allow a moderator to invite people to a group" do
      @user = @moderator
      invitees = { :invitees => ["leonard@example.com", "sheldon@example.com"] }
      expect {
        @json = api_call(:post, "#{@community_path}/invite", @category_path_options.merge(:group_id => @community.to_param, :action => "invite"), invitees)
      }.to change(User, :count).by(2)
      @memberships = @community.reload.group_memberships.where(:workflow_state => "invited").order(:id).all
      @memberships.count.should == 2
      @json.sort_by{ |a| a['id'] }.should == @memberships.map{ |gm| membership_json(gm) }
    end

    it "should not allow a member to invite people to a group" do
      @user = @member
      invitees = { :invitees => ["leonard@example.com", "sheldon@example.com"] }
      api_call(:post, "#{@community_path}/invite", @category_path_options.merge(:group_id => @community.to_param, :action => "invite"), invitees, {}, :expected_status => 401)
      @memberships = @community.reload.group_memberships.where(:workflow_state => "invited").order(:id).count.should == 0
    end

    it "should find people when inviting to a group in a non-default account" do
      @account = Account.create!
      @category = @account.group_categories.create!(name: "foo")
      @group = group_model(:name => "Blah", :group_category => @category, :context => @account)

      @moderator = user_model
      @group.add_user(@moderator, 'accepted', true)

      @member = user_with_pseudonym(:account => @account)

      @user = @moderator
      api_call(
        :post,
        "/api/v1/groups/#{@group.id}/invite",
        { :controller => "groups", :format => "json", :group_id => @group.to_param, :action => "invite" },
        { :invitees => [@member.pseudonym.unique_id]},
        {},
        { :domain_root_account => @account })

      @member.group_memberships.count.should == 1
    end

    it "should allow being added to a non-community account group" do
      @account = Account.default
      @category = @account.group_categories.create!(name: "foo")
      @group = group_model(:group_category => @category, :context => @account)

      @to_add = user_with_pseudonym(:account => @account, :active_all => true)
      @user = account_admin_user(:account => @account, :active_all => true)
      json = api_call(
        :post,
        "/api/v1/groups/#{@group.id}/memberships",
        @memberships_path_options.merge(:group_id => @group.to_param, :action => "create"),
        { :user_id => @to_add.id })

      @membership = GroupMembership.where(:user_id => @to_add, :group_id => @group).first
      @membership.workflow_state.should == "accepted"
      json.should == membership_json(@membership, true).merge("just_created" => true)
    end

    it "should show sis_import_id for group" do
      user_model
      sis_batch = @community.root_account.sis_batches.create
      SisBatch.where(id: sis_batch).update_all(workflow_state: 'imported')
      membership = @community.add_user(@user, 'invited')
      membership.sis_batch_id = sis_batch.id
      membership.save!
      @user = account_admin_user(:account => @account, :active_all => true)
      json = api_call(:get, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "index"), {
        :filter_states => ["invited"]
      })
      json.first['sis_import_id'].should == sis_batch.id
      json.first.should == membership_json(@community.group_memberships.where(:workflow_state => 'invited').first, true)
    end
  end

  context "users" do
    let(:api_url) { "/api/v1/groups/#{@community.id}/users.json" }
    let(:api_route) do
      {
          :controller => 'groups',
          :action => 'users',
          :group_id => @community.to_param,
          :format => 'json'
      }
    end

    it "should return users in a group" do
      expected_keys = %w{id name sortable_name short_name}
      json = api_call(:get, "/api/v1/groups/#{@community.id}/users",
                      { :controller => 'groups', :action => 'users', :group_id => @community.to_param, :format => 'json' })
      json.count.should == 2
      json.each do |user|
        (user.keys & expected_keys).sort.should == expected_keys.sort
        @community.users.map(&:id).should include(user['id'])
      end
    end

    it "should return 401 for users outside the group" do
      user
      raw_api_call(:get, "/api/v1/groups/#{@community.id}/users",
                         { :controller => 'groups', :action => 'users', :group_id => @community.to_param, :format => 'json' })
      response.code.should == '401'
    end

    it "returns an error when search_term is fewer than 3 characters" do
      json = api_call(:get, api_url, api_route, {:search_term => 'ab'}, {}, :expected_status => 400)
      error = json["errors"].first
      verify_json_error(error, "search_term", "invalid", "3 or more characters is required")
    end

    it "returns a list of users" do
      expected_keys = %w{id name sortable_name short_name}

      json = api_call(:get, api_url, api_route, {:search_term => 'value'})

      json.count.should == 1
      json.each do |user|
        (user.keys & expected_keys).sort.should == expected_keys.sort
        @community.users.map(&:id).should include(user['id'])
      end
    end

    it "honors the include[avatar_url] query parameter flag" do
      account = @community.context
      account.set_service_availability(:avatars, true)
      account.save!

      user = @community.users.first
      user.avatar_image_url = "http://expected_avatar_url"
      user.save!

      json = api_call(:get, api_url + "?include[]=avatar_url", api_route.merge(include: ["avatar_url"]))
      json.first['avatar_url'].should == user.avatar_image_url
    end
  end

  context "group files" do
    include_examples "file uploads api with folders"
    include_examples "file uploads api with quotas"

    before do
      @user = @member
    end

    def preflight(preflight_params)
      api_call(:post, "/api/v1/groups/#{@community.id}/files",
        { :controller => "groups", :action => "create_file", :format => "json", :group_id => @community.to_param, },
        preflight_params)
    end

    def has_query_exemption?
      false
    end

    def context
      @community
    end
  end

  it "should return the activity stream" do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    @group = @course.groups.create!(:name => 'Group 1')
    @group.users << @user
    @context = @group
    @topic1 = discussion_topic_model
    json = api_call(:get, "/api/v1/groups/#{@group.id}/activity_stream.json",
                    { controller: "groups", group_id: @group.id.to_s, action: "activity_stream", format: 'json' })
    json.size.should == 1
  end

  it "should return the activity stream summary" do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    @group = @course.groups.create!(:name => 'Group 1')
    @group.users << @user
    @context = @group
    @topic1 = discussion_topic_model
    json = api_call(:get, "/api/v1/groups/#{@group.id}/activity_stream/summary.json",
                    { controller: "groups", group_id: @group.id.to_s, action: "activity_stream_summary", format: 'json' })
    json.should == [{"type" => "DiscussionTopic", "count" => 1, "unread_count" => 1, "notification_category" => nil}]
  end

  describe "/preview_html" do
    before :once do
      course_with_teacher_logged_in(:active_all => true)
      @group = @course.groups.create!(:name => 'Group 1')
    end

    it "should sanitize html and process links" do
      @user = @teacher
      attachment_model(:context => @group)
      html = %{<p><a href="/files/#{@attachment.id}/download?verifier=huehuehuehue">Click!</a><script></script></p>}
      json = api_call(:post, "/api/v1/groups/#{@group.id}/preview_html",
                      { :controller => 'groups', :action => 'preview_html', :group_id => @group.to_param, :format => 'json' },
                      { :html => html})

      returned_html = json["html"]
      returned_html.should_not include("<script>")
      returned_html.should include("/groups/#{@group.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}")
    end

    it "should require permission to preview" do
      @user = user
      api_call(:post, "/api/v1/groups/#{@group.id}/preview_html",
                      { :controller => 'groups', :action => 'preview_html', :group_id => @group.to_param, :format => 'json' },
                      { :html => ""}, {}, {:expected_status => 401})

    end
  end
end
