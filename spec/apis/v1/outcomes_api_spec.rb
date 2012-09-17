
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

describe "Outcomes API", :type => :integration do
  before :each do
    Pseudonym.any_instance.stubs(:works_for_account?).returns(true)
    user_with_pseudonym(:active_all => true)
  end

  def revoke_permission(account_user, permission)
    RoleOverride.manage_role_override(account_user.account, account_user.membership_type, permission.to_s, :override => false)
  end

  before :each do
    @account = Account.default
    @account_user = @user.account_users.create(:account => @account)
    @outcome = @account.created_learning_outcomes.create!(
      :title => "My Outcome",
      :description => "Description of my outcome")
  end

  describe "show" do
    it "should not require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                   :controller => 'outcomes_api',
                   :action => 'show',
                   :id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 200
    end

    it "should 404 for deleted outcomes" do
      @outcome.destroy
      raw_api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                   :controller => 'outcomes_api',
                   :action => 'show',
                   :id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 404
    end

    it "should return the outcome json" do
      json = api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                   :controller => 'outcomes_api',
                   :action => 'show',
                   :id => @outcome.id.to_s,
                   :format => 'json')
      json.should == {
        "id" => @outcome.id,
        "context_id" => @account.id,
        "context_type" => "Account",
        "title" => @outcome.title,
        "url" => api_v1_outcome_path(:id => @outcome.id),
        "can_edit" => true,
        "description" => @outcome.description
      }
    end

    it "should include criterion if it has one" do
      criterion = {
        :mastery_points => 3,
        :ratings => [
          { :points => 5, :description => "Exceeds Expectations" },
          { :points => 3, :description => "Meets Expectations" },
          { :points => 0, :description => "Does Not Meet Expectations" }
        ]
      }
      @outcome.rubric_criterion = criterion
      @outcome.save!

      json = api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                   :controller => 'outcomes_api',
                   :action => 'show',
                   :id => @outcome.id.to_s,
                   :format => 'json')

      json.should == {
        "id" => @outcome.id,
        "context_id" => @account.id,
        "context_type" => "Account",
        "title" => @outcome.title,
        "url" => api_v1_outcome_path(:id => @outcome.id),
        "can_edit" => true,
        "description" => @outcome.description,
        "points_possible" => 5,
        "mastery_points" => 3,
        "ratings" => [
          { "points" => 5, "description" => "Exceeds Expectations" },
          { "points" => 3, "description" => "Meets Expectations" },
          { "points" => 0, "description" => "Does Not Meet Expectations" }
        ]
      }
    end
  end

  describe "update" do
    it "should require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                   :controller => 'outcomes_api',
                   :action => 'update',
                   :id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should require manage_global_outcomes permission for global outcomes" do
      @account_user = @user.account_users.create(:account => Account.site_admin)
      @outcome = LearningOutcome.global.create!(:title => 'global')
      revoke_permission(@account_user, :manage_global_outcomes)
      raw_api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                   :controller => 'outcomes_api',
                   :action => 'update',
                   :id => @outcome.id.to_s,
                   :format => 'json')
      response.status.to_i.should == 401
    end

    it "should fail (400) if the outcome is invalid" do
      too_long_description = ([0] * (ActiveRecord::Base.maximum_text_length + 1)).join('')
      raw_api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
               { :controller => 'outcomes_api',
                 :action => 'update',
                 :id => @outcome.id.to_s,
                 :format => 'json' },
               { :title => "Updated Outcome",
                 :description => too_long_description,
                 :mastery_points => 5,
                 :ratings => [
                   { :points => 10, :description => "Exceeds Expectations" },
                   { :points => 5, :description => "Meets Expectations" },
                   { :points => 0, :description => "Does Not Meet Expectations" }
                 ]
               })
      response.status.to_i.should == 400
    end

    it "should update the outcome" do
      api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
               { :controller => 'outcomes_api',
                 :action => 'update',
                 :id => @outcome.id.to_s,
                 :format => 'json' },
               { :title => "Updated Outcome",
                 :description => "Description of updated outcome",
                 :mastery_points => 5,
                 :ratings => [
                   { :points => 10, :description => "Exceeds Expectations" },
                   { :points => 5, :description => "Meets Expectations" },
                   { :points => 0, :description => "Does Not Meet Expectations" }
                 ]
               })
      @outcome.reload
      @outcome.title.should == "Updated Outcome"
      @outcome.description.should == "Description of updated outcome"
      @outcome.data[:rubric_criterion].should == {
        :description => 'Updated Outcome',
        :mastery_points => 5,
        :points_possible => 10,
        :ratings => [
          { :points => 10, :description => "Exceeds Expectations" },
          { :points => 5, :description => "Meets Expectations" },
          { :points => 0, :description => "Does Not Meet Expectations" }
        ]
      }
    end

    it "should leave alone fields not provided" do
      api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
               { :controller => 'outcomes_api',
                 :action => 'update',
                 :id => @outcome.id.to_s,
                 :format => 'json' },
               { :title => "New Title" })

      @outcome.reload
      @outcome.title.should == "New Title"
      @outcome.description.should == "Description of my outcome"
    end

    it "should return the updated outcome json" do
      json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
               { :controller => 'outcomes_api',
                 :action => 'update',
                 :id => @outcome.id.to_s,
                 :format => 'json' },
               { :title => "New Title",
                 :description => "New Description" })

      json.should == {
        "id" => @outcome.id,
        "context_id" => @account.id,
        "context_type" => "Account",
        "title" => "New Title",
        "url" => api_v1_outcome_path(:id => @outcome.id),
        "can_edit" => true,
        "description" => "New Description"
      }
    end
  end
end
