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
  def group_json(group)
    {
      'id' => group.id,
      'name' => group.name,
      'description' => group.description,
      'is_public' => group.is_public,
      'join_level' => group.join_level,
      'members_count' => group.members_count,
      'group_category_id' => group.group_category_id,
    }
  end

  before do
    @moderator = user_model
    @member = user_with_pseudonym

    @group_category = GroupCategory.communities_for(Account.default)
    group_model(:name => "Algebra Teachers", :group_category => @group_category)
    @group.add_user(@member, 'accepted', false)
    @group.add_user(@moderator, 'accepted', true)
    @group_path = "/api/v1/groups/#{@group.id}"
    @group_path_options = { :controller => "groups", :format => "json" }
    @group_json = group_json(@group)
  end

  it "should allow a member to retrieve the group" do
    @user = @member
    json = api_call(:get, @group_path, @group_path_options.merge(:group_id => @group.to_param, :action => "show"))
    json.should == @group_json
  end

  it "should allow anyone to create a new community" do
    user_model
    json = api_call(:post, "/api/v1/groups", @group_path_options.merge(:action => "create"), {
      'name'=> "History Teachers",
      'description' => "Because history is awesome!",
      'is_public'=> false,
      'join_level'=> "parent_context_request",
    })
    @group2 = Group.last(:order => :id)
    @group2.group_category.should be_communities
    json.should == group_json(@group2)
  end

  it "should allow a moderator to edit a group" do
    @user = @moderator
    new_attrs = {
      'name' => "Algebra II Teachers",
      'description' => "Math rocks!",
      'is_public' => true,
      'join_level' => "parent_context_auto_join",
    }
    json = api_call(:put, @group_path, @group_path_options.merge(:group_id => @group.to_param, :action => "update"), new_attrs)
    @group.reload
    @group.name.should == "Algebra II Teachers"
    @group.description.should == "Math rocks!"
    @group.is_public.should == true
    @group.join_level.should == "parent_context_auto_join"
    json.should == @group_json.merge(new_attrs)
  end

  it "should only allow updating a group from private to public" do
    @user = @moderator
    new_attrs = {
      'is_public' => true,
    }
    json = api_call(:put, @group_path, @group_path_options.merge(:group_id => @group.to_param, :action => "update"), new_attrs)
    @group.reload
    @group.is_public.should == true

    new_attrs = {
      'is_public' => false,
    }
    json = api_call(:put, @group_path, @group_path_options.merge(:group_id => @group.to_param, :action => "update"), new_attrs, {}, :expected_status => 400)
    @group.reload
    @group.is_public.should == true
  end

  it "should not allow a member to edit a group" do
    @user = @member
    new_attrs = {
      'name'=> "Algebra II Teachers",
      'is_public'=> true,
      'join_level'=> "parent_context_auto_join",
    }
    json = api_call(:put, @group_path, @group_path_options.merge(:group_id => @group.to_param, :action => "update"), new_attrs, {}, :expected_status => 401)
    json['message'].should match /not authorized/
  end

  it "should allow a moderator to delete a group" do
    @user = @moderator
    json = api_call(:delete, @group_path, @group_path_options.merge(:group_id => @group.to_param, :action => "destroy"))
    json.should == @group_json.merge({ 'members_count' => 0 })
  end

  it "should not allow a member to delete a group" do
    @user = @member
    json = api_call(:delete, @group_path, @group_path_options.merge(:group_id => @group.to_param, :action => "destroy"), {}, {}, :expected_status => 401)
    json['message'].should match /not authorized/
  end

  context "group files" do
    it_should_behave_like "file uploads api with folders"

    before do
      @user = @member
    end

    def preflight(preflight_params)
      api_call(:post, "/api/v1/groups/#{@group.id}/files",
        { :controller => "groups", :action => "create_file", :format => "json", :group_id => @group.to_param, },
        preflight_params)
    end

    def context
      @group
    end
  end
end
