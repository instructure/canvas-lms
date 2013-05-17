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

describe "Outcome Groups API", :type => :integration do
  before :each do
    Pseudonym.any_instance.stubs(:works_for_account?).returns(true)
    user_with_pseudonym(:active_all => true)
  end

  def revoke_permission(account_user, permission)
    RoleOverride.manage_role_override(account_user.account, account_user.membership_type, permission.to_s, :override => false)
  end

  def create_outcome(opts={})
    group = opts.delete(:group) || @group
    account = opts.delete(:account) || @account
    outcome = account.created_learning_outcomes.create!({:title => 'new outcome'}.merge(opts))
    group.add_outcome(outcome)
  end

  describe "redirect" do
    describe "global context" do
      before :each do
        @account_user = @user.account_users.create(:account => Account.site_admin)
      end

      it "should not require permission" do
        revoke_permission(@account_user, :manage_outcomes)
        revoke_permission(@account_user, :manage_global_outcomes)
        raw_api_call(:get, "/api/v1/global/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :format => 'json')
        response.status.to_i.should == 302
      end

      it "should require a user" do
        @user = nil
        raw_api_call(:get, "/api/v1/global/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :format => 'json')
        response.status.to_i.should == 401
      end

      it "should redirect to the root global group" do
        root = LearningOutcomeGroup.global_root_outcome_group
        raw_api_call(:get, "/api/v1/global/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :format => 'json')
        response.status.to_i.should == 302
        response.location.should == polymorphic_url([:api_v1, :global, :outcome_group], :id => root.id)
      end

      it "should create the root global group if necessary" do
        LearningOutcomeGroup.update_all(:workflow_state => 'deleted')
        raw_api_call(:get, "/api/v1/global/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :format => 'json')
        id = response.location.scan(/\d+$/).first.to_i
        root = LearningOutcomeGroup.global_root_outcome_group
        root.id.should == id
        root.should be_active
      end
    end

    describe "account context" do
      before :each do
        @account = Account.default
        @account_user = @user.account_users.create(:account => @account)
      end

      it "should not require manage permission to read" do
        revoke_permission(@account_user, :manage_outcomes)
        raw_api_call(:get, "/api/v1/accounts/#{@account.id}/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :account_id => @account.id.to_s,
                     :format => 'json')
        response.status.to_i.should == 302
      end

      it "should require read permission to read" do
        # new user, doesn't have a tie to the account
        user_with_pseudonym(:account => Account.create!, :active_all => true)
        raw_api_call(:get, "/api/v1/accounts/#{@account.id}/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :account_id => @account.id.to_s,
                     :format => 'json')
        response.status.to_i.should == 401
      end

      it "should redirect to the root group" do
        root = @account.root_outcome_group
        raw_api_call(:get, "/api/v1/accounts/#{@account.id}/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :account_id => @account.id.to_s,
                     :format => 'json')
        response.status.to_i.should == 302
        response.location.should == polymorphic_url([:api_v1, @account, :outcome_group], :id => root.id)
      end

      it "should create the root group if necessary" do
        @account.learning_outcome_groups.update_all(:workflow_state => 'deleted')
        raw_api_call(:get, "/api/v1/accounts/#{@account.id}/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :account_id => @account.id.to_s,
                     :format => 'json')
        id = response.location.scan(/\d+$/).first.to_i
        root = @account.root_outcome_group
        root.id.should == id
        root.should be_active
      end
    end

    describe "course context" do
      it "should be recognized also" do
        course_with_teacher(:user => @user, :active_all => true)
        root = @course.root_outcome_group
        raw_api_call(:get, "/api/v1/courses/#{@course.id}/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :course_id => @course.id.to_s,
                     :format => 'json')
        response.status.to_i.should == 302
        response.location.should == polymorphic_url([:api_v1, @course, :outcome_group], :id => root.id)
      end
    end
  end

  describe "show" do
    describe "global context" do
      before :each do
        @account_user = @user.account_users.create(:account => Account.site_admin)
      end

      it "should not require permission" do
        revoke_permission(@account_user, :manage_outcomes)
        revoke_permission(@account_user, :manage_global_outcomes)
        group = LearningOutcomeGroup.global_root_outcome_group
        api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')
      end

      it "should 404 for non-global groups" do
        group = Account.default.root_outcome_group
        raw_api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')
        response.status.to_i.should == 404
      end

      it "should 404 for deleted groups" do
        group = LearningOutcomeGroup.global_root_outcome_group.child_outcome_groups.create!(:title => 'subgroup')
        group.destroy
        raw_api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')
        response.status.to_i.should == 404
      end

      it "should return the group json" do
        group = LearningOutcomeGroup.global_root_outcome_group
        json = api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')
        json.should == {
          "id" => group.id,
          "title" => group.title,
          "url" => polymorphic_path([:api_v1, :global, :outcome_group], :id => group.id),
          "can_edit" => true,
          "subgroups_url" => polymorphic_path([:api_v1, :global, :outcome_group_subgroups], :id => group.id),
          "outcomes_url" => polymorphic_path([:api_v1, :global, :outcome_group_outcomes], :id => group.id),
          "import_url" => polymorphic_path([:api_v1, :global, :outcome_group_import], :id => group.id),
          "context_id" => nil,
          "context_type" => nil,
          "description" => group.description
        }
      end

      it "should include parent_outcome_group if non-root" do
        parent_group = LearningOutcomeGroup.global_root_outcome_group
        group = parent_group.child_outcome_groups.create!(
          :title => 'Group Name',
          :description => 'Group Description')

        json = api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')

        json.should == {
          "id" => group.id,
          "title" => group.title,
          "url" => polymorphic_path([:api_v1, :global, :outcome_group], :id => group.id),
          "can_edit" => true,
          "subgroups_url" => polymorphic_path([:api_v1, :global, :outcome_group_subgroups], :id => group.id),
          "outcomes_url" => polymorphic_path([:api_v1, :global, :outcome_group_outcomes], :id => group.id),
          "import_url" => polymorphic_path([:api_v1, :global, :outcome_group_import], :id => group.id),
          "parent_outcome_group" => {
            "id" => parent_group.id,
            "title" => parent_group.title,
            "url" => polymorphic_path([:api_v1, :global, :outcome_group], :id => parent_group.id),
            "subgroups_url" => polymorphic_path([:api_v1, :global, :outcome_group_subgroups], :id => parent_group.id),
            "outcomes_url" => polymorphic_path([:api_v1, :global, :outcome_group_outcomes], :id => parent_group.id),
            "can_edit" => true
          },
          "context_id" => nil,
          "context_type" => nil,
          "description" => group.description
        }
      end
    end

    describe "non-global context" do
      before :each do
        @account = Account.default
        @account_user = @user.account_users.create(:account => @account)
      end

      it "should 404 for groups outside the context" do
        group = LearningOutcomeGroup.global_root_outcome_group
        raw_api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :account_id => @account.id.to_s,
                     :id => group.id.to_s,
                     :format => 'json')
        response.status.to_i.should == 404
      end

      it "should include the account in the group json" do
        group = @account.root_outcome_group
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :account_id => @account.id.to_s,
                     :id => group.id.to_s,
                     :format => 'json')
        json.should == {
          "id" => group.id,
          "title" => group.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => group.id),
          "can_edit" => true,
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => group.id),
          "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => group.id),
          "context_id" => @account.id,
          "context_type" => "Account",
          "description" => group.description
        }
      end
    end
  end

  describe "update" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @root_group = @account.root_outcome_group
      @group = @root_group.child_outcome_groups.create!(
        :title => "Original Title",
        :description => "Original Description")
    end

    it "should require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'update',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should require manage_global_outcomes permission for global outcomes" do
      @account_user = @user.account_users.create(:account => Account.site_admin)
      @root_group = LearningOutcomeGroup.global_root_outcome_group
      @group = @root_group.child_outcome_groups.create!(:title => 'subgroup')
      revoke_permission(@account_user, :manage_global_outcomes)
      raw_api_call(:put, "/api/v1/global/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'update',
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should fail for root groups" do
      @group = @root_group
      raw_api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'update',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 400
    end

    it "should allow setting title and description" do
      api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               { :controller => 'outcome_groups_api',
                 :action => 'update',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "New Title",
                 :description => "New Description" })

      @group.reload
      @group.title.should == "New Title"
      @group.description.should == "New Description"
    end

    it "should leave alone fields not provided" do
      api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               { :controller => 'outcome_groups_api',
                 :action => 'update',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "New Title" })

      @group.reload
      @group.title.should == "New Title"
      @group.description.should == "Original Description"
    end

    it "should allow changing the group's parent" do
      groupA = @root_group.child_outcome_groups.create!(:title => 'subgroup')
      groupB = @root_group.child_outcome_groups.create!(:title => 'subgroup')
      groupC = groupA.child_outcome_groups.create!(:title => 'subgroup')

      api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{groupC.id}",
               { :controller => 'outcome_groups_api',
                 :action => 'update',
                 :account_id => @account.id.to_s,
                 :id => groupC.id.to_s,
                 :format => 'json' },
               { :parent_outcome_group_id => groupB.id })

      groupC.reload
      groupC.parent_outcome_group.should == groupB
      groupA.child_outcome_groups(true).should == []
      groupB.child_outcome_groups(true).should == [groupC]
    end

    it "should fail if changed parentage would create a cycle" do
      child_group = @group.child_outcome_groups.create!(:title => 'subgroup')
      raw_api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
                   { :controller => 'outcome_groups_api',
                     :action => 'update',
                     :account_id => @account.id.to_s,
                     :id => @group.id.to_s,
                     :format => 'json' },
                   { :parent_outcome_group_id => child_group.id })
      response.status.to_i.should == 400
    end

    it "should fail (400) if the update is invalid" do
      too_long_description = ([0] * (ActiveRecord::Base.maximum_text_length + 1)).join('')
      raw_api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               { :controller => 'outcome_groups_api',
                 :action => 'update',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "New Title",
                 :description => too_long_description })
      response.status.to_i.should == 400
    end

    it "should return the updated group json" do
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               { :controller => 'outcome_groups_api',
                 :action => 'update',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "New Title",
                 :description => "New Description" })

      json.should == {
        "id" => @group.id,
        "title" => "New Title",
        "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
        "can_edit" => true,
        "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
        "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
        "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => @group.id),
        "parent_outcome_group" => {
          "id" => @root_group.id,
          "title" => @root_group.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @root_group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @root_group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @root_group.id),
          "can_edit" => true
        },
        "context_id" => @account.id,
        "context_type" => "Account",
        "description" => "New Description"
      }
    end
  end

  describe "destroy" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @root_group = @account.root_outcome_group
      @group = @root_group.child_outcome_groups.create!(:title => 'subgroup')
    end

    it "should require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'destroy',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should require manage_global_outcomes permission for global outcomes" do
      @account_user = @user.account_users.create(:account => Account.site_admin)
      @root_group = LearningOutcomeGroup.global_root_outcome_group
      @group = @root_group.child_outcome_groups.create!(:title => 'subgroup')
      revoke_permission(@account_user, :manage_global_outcomes)
      raw_api_call(:delete, "/api/v1/global/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'destroy',
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should fail for root groups" do
      @group = @root_group
      raw_api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'destroy',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 400
    end

    it "should delete the group" do
      api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               :controller => 'outcome_groups_api',
               :action => 'destroy',
               :account_id => @account.id.to_s,
               :id => @group.id.to_s,
               :format => 'json')

      @group.reload
      @group.should be_deleted
    end

    it "should return json of the deleted group" do
      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               :controller => 'outcome_groups_api',
               :action => 'destroy',
               :account_id => @account.id.to_s,
               :id => @group.id.to_s,
               :format => 'json')

      json.should == {
        "id" => @group.id,
        "title" => 'subgroup',
        "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
        "can_edit" => true,
        "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
        "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
        "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => @group.id),
        "parent_outcome_group" => {
          "id" => @root_group.id,
          "title" => @root_group.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @root_group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @root_group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @root_group.id),
          "can_edit" => true
        },
        "context_id" => @account.id,
        "context_type" => "Account",
        "description" => nil
      }
    end
  end

  describe "outcomes" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @group = @account.root_outcome_group
    end

    it "should NOT require permission to read" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 200
    end

    it "should return the outcomes linked into the group" do
      3.times{ create_outcome }
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      json.sort_by{ |link| link['outcome']['id'] }.should == @account.created_learning_outcomes.map do |outcome|
        {
          "context_type" => "Account",
          "context_id" => @account.id,
          "url" => polymorphic_path([:api_v1, @account, :outcome_link], :id => @group.id, :outcome_id => outcome.id),
          "outcome_group" => {
            "id" => @group.id,
            "title" => @group.title,
            "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
            "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
            "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
            "can_edit" => true
          },
          "outcome" => {
            "id" => outcome.id,
            "context_type" => "Account",
            "context_id" => @account.id,
            "title" => outcome.title,
            "url" => api_v1_outcome_path(:id => outcome.id),
            "can_edit" => true
          }
        }
      end.sort_by{ |link| link['outcome']['id'] }
    end

    it "should not include deleted links" do
      @outcome1 = @account.created_learning_outcomes.create!(:title => 'outcome')
      @outcome2 = @account.created_learning_outcomes.create!(:title => 'outcome')
      @link1 = @group.add_outcome(@outcome1)
      @link2 = @group.add_outcome(@outcome2)
      @link2.destroy

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')

      json.size.should == 1
      json.first['outcome']['id'].should == @outcome1.id
    end

    it "should order links by outcome title" do
      @links = ["B", "A", "C"].map{ |title| create_outcome(:title => title) }
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      json.map{ |link| link['outcome']['id'] }.should ==
        [1, 0, 2].map{ |i| @links[i].content_id }
    end

    it "should paginate the links" do
      links = 25.times.map { |i| create_outcome(:title => "#{i}".object_id) }

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes?per_page=10",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json',
                   :per_page => '10')
      json.size.should eql 10
      response.headers['Link'].should match(%r{<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=2.*>; rel="next",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=1.*>; rel="first",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=3.*>; rel="last"})

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes?per_page=10&page=3",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json',
                   :per_page => '10',
                   :page => '3')
      json.size.should eql 5
      response.headers['Link'].should match(%r{<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=1.*>; rel="prev",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=1.*>; rel="first",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=3.*>; rel="last"})
    end
  end

  describe "link existing" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @group = @account.root_outcome_group
      @outcome = LearningOutcome.global.create!(:title => 'subgroup')
    end

    it "should require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'link',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should require manage_global_outcomes permission for global groups" do
      @account_user = @user.account_users.create(:account => Account.site_admin)
      @group = LearningOutcomeGroup.global_root_outcome_group
      revoke_permission(@account_user, :manage_global_outcomes)
      raw_api_call(:put, "/api/v1/global/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'link',
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should fail if the outcome isn't available to the context" do
      @subaccount = @account.sub_accounts.create!
      @outcome = @subaccount.created_learning_outcomes.create!(:title => 'outcome')
      raw_api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'link',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 400
    end

    it "should link the outcome into the group" do
      @group.child_outcome_links.should be_empty
      api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'link',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      @group.child_outcome_links(true).size.should == 1
      @group.child_outcome_links.first.content.should == @outcome
    end

    it "should return json of the new link" do
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'link',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      json.should == {
        "context_type" => "Account",
        "context_id" => @account.id,
        "url" => polymorphic_path([:api_v1, @account, :outcome_link], :id => @group.id, :outcome_id => @outcome.id),
        "outcome_group" => {
          "id" => @group.id,
          "title" => @group.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
          "can_edit" => true
        },
        "outcome" => {
          "id" => @outcome.id,
          "context_type" => nil,
          "context_id" => nil,
          "title" => @outcome.title,
          "url" => api_v1_outcome_path(:id => @outcome.id),
          "can_edit" => false
        }
      }
    end
  end

  describe "link new" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @group = @account.root_outcome_group
    end

    it "should fail (400) if the new outcome is invalid" do
      too_long_description = ([0] * (ActiveRecord::Base.maximum_text_length + 1)).join('')
      raw_api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
               { :controller => 'outcome_groups_api',
                 :action => 'link',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "My Outcome",
                 :description => too_long_description,
                 :mastery_points => 5,
                 :ratings => [
                   { :points => 5, :description => "Exceeds Expectations" },
                   { :points => 3, :description => "Meets Expectations" },
                   { :points => 0, :description => "Does Not Meet Expectations" }
                 ]
               })
      response.status.to_i.should == 400
    end

    it "should create a new outcome" do
      LearningOutcome.update_all(:workflow_state => 'deleted')
      api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
               { :controller => 'outcome_groups_api',
                 :action => 'link',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "My Outcome",
                 :description => "Description of my outcome",
                 :mastery_points => 5,
                 :ratings => [
                   { :points => 5, :description => "Exceeds Expectations" },
                   { :points => 3, :description => "Meets Expectations" },
                   { :points => 0, :description => "Does Not Meet Expectations" }
                 ]
               })
      LearningOutcome.active.count.should == 1
      @outcome = LearningOutcome.active.first
      @outcome.title.should == "My Outcome"
      @outcome.description.should == "Description of my outcome"
      @outcome.data[:rubric_criterion].should == {
        :description => 'My Outcome',
        :mastery_points => 5,
        :points_possible => 5,
        :ratings => [
          { :points => 5, :description => "Exceeds Expectations" },
          { :points => 3, :description => "Meets Expectations" },
          { :points => 0, :description => "Does Not Meet Expectations" }
        ]
      }
    end

    it "should link the new outcome into the group" do
      LearningOutcome.update_all(:workflow_state => 'deleted')
      api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
               { :controller => 'outcome_groups_api',
                 :action => 'link',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "My Outcome",
                 :description => "Description of my outcome" })
      @outcome = LearningOutcome.active.first
      @group.child_outcome_links.count.should == 1
      @group.child_outcome_links.first.content.should == @outcome
    end
  end

  describe "unlink" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @group = @account.root_outcome_group
      @outcome = LearningOutcome.global.create!(:title => 'outcome')
      @group.add_outcome(@outcome)
    end

    it "should require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'unlink',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should require manage_global_outcomes permission for global groups" do
      @account_user = @user.account_users.create(:account => Account.site_admin)
      @group = LearningOutcomeGroup.global_root_outcome_group
      @group.add_outcome(@outcome)
      revoke_permission(@account_user, :manage_global_outcomes)
      raw_api_call(:delete, "/api/v1/global/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'unlink',
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should 404 if the outcome isn't linked in the group" do
      @outcome = LearningOutcome.global.create!(:title => 'outcome')
      raw_api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'unlink',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 404
    end

    it "should fail (400) if this is the last link for an aligned outcome" do
      aqb = @account.assessment_question_banks.create!
      @outcome.align(aqb, @account, :mastery_type => "none")
      raw_api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'unlink',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 400
      parsed_body = JSON.parse( response.body )
      parsed_body[ 'message' ].should =~ /link is the last link/i
    end

    it "should unlink the outcome from the group" do
      @group.child_outcome_links.active.size.should == 1
      api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'unlink',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      @group.child_outcome_links.active.size.should == 0
    end

    it "should return json of the removed link" do
      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'unlink',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      json.should == {
        "context_type" => "Account",
        "context_id" => @account.id,
        "url" => polymorphic_path([:api_v1, @account, :outcome_link], :id => @group.id, :outcome_id => @outcome.id),
        "outcome_group" => {
          "id" => @group.id,
          "title" => @group.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
          "can_edit" => true
        },
        "outcome" => {
          "id" => @outcome.id,
          "context_type" => nil,
          "context_id" => nil,
          "title" => @outcome.title,
          "url" => api_v1_outcome_path(:id => @outcome.id),
          "can_edit" => false
        }
      }
    end
  end

  describe "subgroups" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @group = @account.root_outcome_group
    end

    it "should NOT require permission to read" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 200
    end

    def create_subgroup(opts={})
      group = opts.delete(:group) || @group
      group.child_outcome_groups.create!({:title => 'subgroup'}.merge(opts))
    end

    it "should return the subgroups under the group" do
      3.times{ create_subgroup }
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      json.sort_by{ |subgroup| subgroup['id'] }.should == @group.child_outcome_groups.map do |subgroup|
        {
          "id" => subgroup.id,
          "title" => subgroup.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => subgroup.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => subgroup.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => subgroup.id),
          "can_edit" => true
        }
      end.sort_by{ |subgroup| subgroup['id'] }
    end

    it "should not include deleted subgroups" do
      @subgroup1 = create_subgroup
      @subgroup2 = create_subgroup
      @subgroup2.destroy

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')

      json.size.should == 1
      json.first['id'].should == @subgroup1.id
    end

    it "should order subgroups by title" do
      @subgroups = ["B", "A", "C"].map{ |title| create_subgroup(:title => title) }
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      json.map{ |link| link['id'] }.should ==
        [1, 0, 2].map{ |i| @subgroups[i].id }
    end

    it "should paginate the subgroups" do
      subgroups = 25.times.map { |i| create_subgroup }

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups?per_page=10",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json',
                   :per_page => '10')
      json.size.should eql 10
      response.headers['Link'].should match(%r{<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=2.*>; rel="next",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=1.*>; rel="first",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=3.*>; rel="last"})

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups?per_page=10&page=3",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json',
                   :per_page => '10',
                   :page => '3')
      json.size.should eql 5
      response.headers['Link'].should match(%r{<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=1.*>; rel="prev",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=1.*>; rel="first",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=3.*>; rel="last"})
    end
  end

  describe "create" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @group = @account.root_outcome_group
    end

    it "should require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
                   :controller => 'outcome_groups_api',
                   :action => 'create',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should require manage_global_outcomes permission for global groups" do
      @account_user = @user.account_users.create(:account => Account.site_admin)
      @group = LearningOutcomeGroup.global_root_outcome_group
      revoke_permission(@account_user, :manage_global_outcomes)
      raw_api_call(:post, "/api/v1/global/outcome_groups/#{@group.id}/subgroups",
                   :controller => 'outcome_groups_api',
                   :action => 'create',
                   :id => @group.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should create a new outcome group" do
      @group.child_outcome_groups.size.should == 0
      api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
               { :controller => 'outcome_groups_api',
                 :action => 'create',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "My Subgroup",
                 :description => "Description of my subgroup" })
      @group.child_outcome_groups.active.size.should == 1
      @subgroup = @group.child_outcome_groups.active.first
      @subgroup.title.should == "My Subgroup"
      @subgroup.description.should == "Description of my subgroup"
    end

    it "should return json of the new subgroup" do
      json = api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
               { :controller => 'outcome_groups_api',
                 :action => 'create',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "My Subgroup",
                 :description => "Description of my subgroup" })
      @subgroup = @group.child_outcome_groups.active.first
      json.should == {
        "id" => @subgroup.id,
        "title" => @subgroup.title,
        "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @subgroup.id),
        "can_edit" => true,
        "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @subgroup.id),
        "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @subgroup.id),
        "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => @subgroup.id),
        "parent_outcome_group" => {
          "id" => @group.id,
          "title" => @group.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
          "can_edit" => true
        },
        "context_id" => @account.id,
        "context_type" => "Account",
        "description" => @subgroup.description
      }
    end
  end

  describe "import" do
    before :each do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @source_group = LearningOutcomeGroup.global_root_outcome_group.child_outcome_groups.create!(
        :title => "Source Group",
        :description => "Description of source group")
      @target_group = @account.root_outcome_group
    end

    it "should require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@target_group.id}/import",
                   { :controller => 'outcome_groups_api',
                     :action => 'import',
                     :account_id => @account.id.to_s,
                     :id => @target_group.id.to_s,
                     :format => 'json' },
                   { :source_outcome_group_id => @source_group.id.to_s })
      response.status.to_i.should == 401
    end

    it "should require manage_global_outcomes permission for global groups" do
      @account_user = @user.account_users.create(:account => Account.site_admin)
      @target_group = LearningOutcomeGroup.global_root_outcome_group
      revoke_permission(@account_user, :manage_global_outcomes)
      raw_api_call(:post, "/api/v1/global/outcome_groups/#{@target_group.id}/import",
                   { :controller => 'outcome_groups_api',
                     :action => 'import',
                     :id => @target_group.id.to_s,
                     :format => 'json' },
                   { :source_outcome_group_id => @source_group.id.to_s })
      response.status.to_i.should == 401
    end

    it "should fail if the source group doesn't exist (or is deleted)" do
      @source_group.destroy
      revoke_permission(@account_user, :manage_global_outcomes)
      raw_api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@target_group.id}/import",
                   { :controller => 'outcome_groups_api',
                     :action => 'import',
                     :account_id => @account.id.to_s,
                     :id => @target_group.id.to_s,
                     :format => 'json' },
                   { :source_outcome_group_id => @source_group.id.to_s })
      response.status.to_i.should == 400
    end

    it "should fail if the source group isn't available to the context" do
      @subaccount = @account.sub_accounts.create!
      @source_group = @subaccount.root_outcome_group.child_outcome_groups.create!(:title => 'subgroup')
      raw_api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@target_group.id}/import",
                   { :controller => 'outcome_groups_api',
                     :action => 'import',
                     :account_id => @account.id.to_s,
                     :id => @target_group.id.to_s,
                     :format => 'json' },
                   { :source_outcome_group_id => @source_group.id.to_s })
      response.status.to_i.should == 400
    end

    it "should create a new outcome group" do
      @target_group.child_outcome_groups.size.should == 0
      api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@target_group.id}/import",
                   { :controller => 'outcome_groups_api',
                     :action => 'import',
                     :account_id => @account.id.to_s,
                     :id => @target_group.id.to_s,
                     :format => 'json' },
                   { :source_outcome_group_id => @source_group.id.to_s })
      @target_group.child_outcome_groups.active.size.should == 1
      @subgroup = @target_group.child_outcome_groups.active.first
      @subgroup.title.should == @source_group.title
      @subgroup.description.should == @source_group.description
    end

    it "should return json of the new subgroup" do
      json = api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@target_group.id}/import",
                   { :controller => 'outcome_groups_api',
                     :action => 'import',
                     :account_id => @account.id.to_s,
                     :id => @target_group.id.to_s,
                     :format => 'json' },
                   { :source_outcome_group_id => @source_group.id.to_s })
      @subgroup = @target_group.child_outcome_groups.active.first
      json.should == {
        "id" => @subgroup.id,
        "title" => @subgroup.title,
        "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @subgroup.id),
        "can_edit" => true,
        "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @subgroup.id),
        "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @subgroup.id),
        "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => @subgroup.id),
        "parent_outcome_group" => {
          "id" => @target_group.id,
          "title" => @target_group.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @target_group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @target_group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @target_group.id),
          "can_edit" => true
        },
        "context_id" => @account.id,
        "context_type" => "Account",
        "description" => @subgroup.description
      }
    end
  end
end
