#
# Copyright (C) 2012 Instructure, Inc.
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

describe "Groups API", :type => :integration do
  def group_json(group, user)
    {
      'id' => group.id,
      'name' => group.name,
      'description' => group.description,
      'is_public' => group.is_public,
      'join_level' => group.join_level,
      'members_count' => group.members_count,
      'avatar_url' => group.avatar_attachment && "http://www.example.com/images/thumbnails/#{group.avatar_attachment.id}/#{group.avatar_attachment.uuid}",
      'group_category_id' => group.group_category_id,
      'followed_by_user' => group.followers.include?(user),
    }
  end

  def membership_json(membership)
    {
      'id' => membership.id,
      'group_id' => membership.group_id,
      'user_id' => membership.user_id,
      'workflow_state' => membership.workflow_state,
      'moderator' => membership.moderator,
    }
  end

  before do
    @moderator = user_model
    @member = user_with_pseudonym

    @communities = GroupCategory.communities_for(Account.default)
    @community = group_model(:name => "Algebra Teachers", :group_category => @communities)
    @community.add_user(@member, 'accepted', false)
    @community.add_user(@moderator, 'accepted', true)
    @community_path = "/api/v1/groups/#{@community.id}"
    @community_path_options = { :controller => "groups", :format => "json" }
  end

  it "should allow a member to retrieve the group" do
    @user = @member
    json = api_call(:get, @community_path, @community_path_options.merge(:group_id => @community.to_param, :action => "show"))
    json.should == group_json(@community, @user)
  end

  it "should allow anyone to create a new community" do
    user_model
    json = api_call(:post, "/api/v1/groups", @community_path_options.merge(:action => "create"), {
      'name'=> "History Teachers",
      'description' => "Because history is awesome!",
      'is_public'=> false,
      'join_level'=> "parent_context_request",
    })
    @community2 = Group.last(:order => :id)
    @community2.group_category.should be_communities
    json.should == group_json(@community2, @user)
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
    json = api_call(:put, @community_path, @community_path_options.merge(:group_id => @community.to_param, :action => "update"), new_attrs)
    @community.reload
    @community.name.should == "Algebra II Teachers"
    @community.description.should == "Math rocks!"
    @community.is_public.should == true
    @community.join_level.should == "parent_context_auto_join"
    @community.avatar_attachment.should == avatar
    json.should == group_json(@community, @user)
  end

  it "should only allow updating a group from private to public" do
    @user = @moderator
    new_attrs = {
      'is_public' => true,
    }
    json = api_call(:put, @community_path, @community_path_options.merge(:group_id => @community.to_param, :action => "update"), new_attrs)
    @community.reload
    @community.is_public.should == true

    new_attrs = {
      'is_public' => false,
    }
    json = api_call(:put, @community_path, @community_path_options.merge(:group_id => @community.to_param, :action => "update"), new_attrs, {}, :expected_status => 400)
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
    json = api_call(:put, @community_path, @community_path_options.merge(:group_id => @community.to_param, :action => "update"), new_attrs, {}, :expected_status => 401)
    json['message'].should match /not authorized/
  end

  it "should allow a moderator to delete a group" do
    @user = @moderator
    json = api_call(:delete, @community_path, @community_path_options.merge(:group_id => @community.to_param, :action => "destroy"))
    @community.reload.workflow_state.should == 'deleted'
  end

  it "should not allow a member to delete a group" do
    @user = @member
    json = api_call(:delete, @community_path, @community_path_options.merge(:group_id => @community.to_param, :action => "destroy"), {}, {}, :expected_status => 401)
    json['message'].should match /not authorized/
  end

  describe "following" do
    it "should allow following a public group" do
      user_model
      @community.update_attribute(:is_public, true)
      json = api_call(:put, @community_path + "/followers/self", @community_path_options.merge(:group_id => @community.to_param, :action => "follow"))
      @user.user_follows.map(&:followed_item).should == [@community]
      uf = @user.user_follows.first
      json.should == { "following_user_id" => @user.id, "followed_group_id" => @community.id, "created_at" => uf.created_at.as_json }
    end

    it "should not allow following a private group" do
      user_model
      json = api_call(:put, @community_path + "/followers/self", @community_path_options.merge(:group_id => @community.to_param, :action => "follow"), {}, {}, :expected_status => 401)
    end

    it "should allow members to follow a private group" do
      @user = @member
      api_call(:put, @community_path + "/followers/self", @community_path_options.merge(:group_id => @community.to_param, :action => "follow"))
      @user.user_follows.map(&:followed_item).should == [@community]
    end
  end

  describe "unfollowing" do
    it "should allow unfollowing a group" do
      @user = @member
      @user.reload.user_follows.map(&:followed_item).should == [@community]

      json = api_call(:delete, @community_path + "/followers/self", @community_path_options.merge(:group_id => @community.to_param, :action => "unfollow"))
      @user.reload.user_follows.should == []
    end

    it "should do nothing if not following" do
      @user = @member
      json = api_call(:delete, @community_path + "/followers/self", @community_path_options.merge(:group_id => @community.to_param, :action => "unfollow"))
      @user.reload.user_follows.should == []

      json = api_call(:delete, @community_path + "/followers/self", @community_path_options.merge(:group_id => @community.to_param, :action => "unfollow"))
      @user.reload.user_follows.should == []
    end
  end

  context "memberships" do
    before do
      @memberships_path = "#{@community_path}/memberships"
      @memberships_path_options = { :controller => "group_memberships", :format => "json" }
    end

    it "should allow listing the group memberships" do
      @user = @moderator
      json = api_call(:get, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "index"))
      json.sort{ |a,b| a['id'] <=> b['id'] }.should == [membership_json(@community.has_member?(@member)), membership_json(@community.has_member?(@moderator))]
    end

    it "should allow filtering to a certain membership state" do
      user_model
      @community.add_user(@user, 'invited')
      @user = @moderator
      json = api_call(:get, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "index"), { 
        :filter_states => ["invited"]
      })
      json.count.should == 1
      json.first.should == membership_json(@community.group_memberships.scoped(:conditions => { :workflow_state => 'invited' }).first)
    end
    
    it "should allow someone to request to join a group" do
      @user = user_model
      @community.join_level = "parent_context_request"
      @community.save!
      json = api_call(:post, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "create"), {
        :user_id => @user.id
      })
      @membership = GroupMembership.scoped(:conditions => { :user_id => @user.id, :group_id => @community.id }).first
      @membership.workflow_state.should == "requested"
      json.should == membership_json(@membership)
    end

    it "should allow someone to join a group" do
      @user = user_model
      @community.join_level = "parent_context_auto_join"
      @community.save!
      json = api_call(:post, @memberships_path, @memberships_path_options.merge(:group_id => @community.to_param, :action => "create"), {
        :user_id => @user.id
      })
      @membership = GroupMembership.scoped(:conditions => { :user_id => @user.id, :group_id => @community.id }).first
      @membership.workflow_state.should == "accepted"
      json.should == membership_json(@membership)
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

    it "should not allow other workflow_state modifications" do
      @user = @moderator
      @membership = @community.group_memberships.find_by_user_id(@member.id)
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

    it "should allow changing moderator privileges" do
      @user = @moderator
      @membership = @community.group_memberships.find_by_user_id(@member.id)
      api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :moderator => true
      })
      @membership.reload.moderator.should be_true

      api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :moderator => false
      })
      @membership.reload.moderator.should be_false
    end

    it "should not allow a member to change moderator privileges" do
      @user = @member
      @membership = @community.group_memberships.find_by_user_id(@moderator.id)
      api_call(:put, "#{@memberships_path}/#{@membership.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @membership.to_param, :action => "update"), {
        :moderator => false
      }, {}, :expected_status => 401)
      @membership.reload.moderator.should be_true
    end

    it "should allow someone to leave a group" do
      @user = @member
      @gm = @community.group_memberships.scoped(:conditions => { :user_id => @user.id }).first
      api_call(:delete, "#{@memberships_path}/#{@gm.id}", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => @gm.to_param, :action => "destroy"))
      @membership = GroupMembership.scoped(:conditions => { :user_id => @user.id, :group_id => @community.id }).first
      @membership.workflow_state.should == "deleted"
    end

    it "should allow leaving a group using 'self'" do
      @user = @member
      api_call(:delete, "#{@memberships_path}/self", @memberships_path_options.merge(:group_id => @community.to_param, :membership_id => 'self', :action => "destroy"))
      @membership = GroupMembership.scoped(:conditions => { :user_id => @user.id, :group_id => @community.id }).first
      @membership.workflow_state.should == "deleted"
    end

    it "should allow a moderator to invite people to a group" do
      @user = @moderator
      invitees = { :invitees => ["leonard@example.com", "sheldon@example.com"] }
      expect {
        @json = api_call(:post, "#{@community_path}/invite", @community_path_options.merge(:group_id => @community.to_param, :action => "invite"), invitees)
      }.to change(User, :count).by(2)
      @memberships = @community.reload.group_memberships.scoped(:conditions => { :workflow_state => "invited" }, :order => :id).all
      @memberships.count.should == 2
      @json.sort{ |a,b| a['id'] <=> b['id'] }.should == @memberships.map{ |gm| membership_json(gm) }
    end

    it "should not allow a member to invite people to a group" do
      @user = @member
      invitees = { :invitees => ["leonard@example.com", "sheldon@example.com"] }
      api_call(:post, "#{@community_path}/invite", @community_path_options.merge(:group_id => @community.to_param, :action => "invite"), invitees, {}, :expected_status => 401)
      @memberships = @community.reload.group_memberships.scoped(:conditions => { :workflow_state => "invited" }, :order => :id).count.should == 0
    end
  end

  context "group files" do
    it_should_behave_like "file uploads api with folders"

    before do
      @user = @member
    end

    def preflight(preflight_params)
      api_call(:post, "/api/v1/groups/#{@community.id}/files",
        { :controller => "groups", :action => "create_file", :format => "json", :group_id => @community.to_param, },
        preflight_params)
    end

    def context
      @community
    end
  end
end
