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

describe "Outcome Groups API", type: :request do
  before :once do
    user_with_pseudonym(:active_all => true)
  end

  def revoke_permission(account_user, permission)
    RoleOverride.manage_role_override(account_user.account, account_user.role, permission.to_s, :override => false)
  end

  def create_outcome(opts={})
    group = opts.delete(:group) || @group
    account = opts.delete(:account) || @account
    @outcome = account.created_learning_outcomes.create!({:title => 'new outcome', :vendor_guid => "vendorguid9000"}.merge(opts))
    group.add_outcome(@outcome)
  end

  def add_or_get_rubric(outcome)
    # This is horribly inefficient, but there's not a good
    # way to query by learning outcome id because it's stored
    # in a serialized field :facepalm:.  When we do our outcomes
    # refactor we should get rid of the serialized field here also
    #
    # Don't create a new rubric if one already exists for this outcome
    Rubric.all.each do |r|
      return r if r.data.first[:learning_outcome_id] == outcome.id
    end

    rubric = Rubric.create!(:context => outcome.context)
    rubric.data = [
      {
        :points => 3,
        :description => "Outcome row",
        :id => 1,
        :ratings => [
          {
            :points => 3,
            :description => "Rockin'",
            :criterion_id => 1,
            :id => 2
          },
          {
            :points => 0,
            :description => "Lame",
            :criterion_id => 1,
            :id => 3
          }
        ],
        :learning_outcome_id => outcome.id
      }
    ]
    rubric.save!
    rubric
  end

  def assess_with(outcome, context, user = nil)
    assignment = assignment_model(context: context)
    rubric = add_or_get_rubric(outcome)
    user ||= user_factory(active_all: true)
    context.enroll_student(user) unless context.student_enrollments.exists?(user_id: user.id)
    a = rubric.associate_with(assignment, context, :purpose => 'grading')
    assignment.reload
    submission = assignment.grade_student(user, grade: "10", grader: @teacher).first
    a.assess({
      :user => user,
      :assessor => user,
      :artifact => submission,
      :assessment => {
        :assessment_type => 'grading',
        :criterion_1 => {
          :points => 2,
          :comments => "cool, yo"
        }
      }
    })
    result = outcome.learning_outcome_results.first
    assessment = a.assess({
      :user => user,
      :assessor => user,
      :artifact => submission,
      :assessment => {
        :assessment_type => 'grading',
        :criterion_1 => {
          :points => 3,
          :comments => "cool, yo"
        }
      }
    })
    result.reload
    rubric.reload
    { assignment: assignment, assessment: assessment, rubric: rubric }
  end

  describe "redirect" do
    describe "global context" do
      before :once do
        @account_user = @user.account_users.create(:account => Account.site_admin)
      end

      it "should not require permission" do
        revoke_permission(@account_user, :manage_outcomes)
        revoke_permission(@account_user, :manage_global_outcomes)
        raw_api_call(:get, "/api/v1/global/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :format => 'json')
        assert_status(302)
      end

      it "should require a user" do
        @user = nil
        raw_api_call(:get, "/api/v1/global/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :format => 'json')
        assert_status(401)
      end

      it "should redirect to the root global group" do
        root = LearningOutcomeGroup.global_root_outcome_group
        raw_api_call(:get, "/api/v1/global/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :format => 'json')
        assert_status(302)
        expect(response.location).to eq polymorphic_url([:api_v1, :global, :outcome_group], :id => root.id)
      end

      it "should create the root global group if necessary" do
        LearningOutcomeGroup.update_all(:workflow_state => 'deleted')
        raw_api_call(:get, "/api/v1/global/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :format => 'json')
        id = response.location.scan(/\d+$/).first.to_i
        root = LearningOutcomeGroup.global_root_outcome_group
        expect(root.id).to eq id
        expect(root).to be_active
      end
    end

    describe "account context" do
      before :once do
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
        assert_status(302)
      end

      it "should require read permission to read" do
        # new user, doesn't have a tie to the account
        user_with_pseudonym(:account => Account.create!, :active_all => true)
        allow_any_instantiation_of(@pseudonym).to receive(:works_for_account?).and_return(true)
        raw_api_call(:get, "/api/v1/accounts/#{@account.id}/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :account_id => @account.id.to_s,
                     :format => 'json')
        assert_status(401)
      end

      it "should redirect to the root group" do
        root = @account.root_outcome_group
        raw_api_call(:get, "/api/v1/accounts/#{@account.id}/root_outcome_group",
                     :controller => 'outcome_groups_api',
                     :action => 'redirect',
                     :account_id => @account.id.to_s,
                     :format => 'json')
        assert_status(302)
        expect(response.location).to eq polymorphic_url([:api_v1, @account, :outcome_group], :id => root.id)
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
        expect(root.id).to eq id
        expect(root).to be_active
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
        assert_status(302)
        expect(response.location).to eq polymorphic_url([:api_v1, @course, :outcome_group], :id => root.id)
      end
    end
  end

  describe "index" do
    before :once do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
    end

    it "should return active groups" do
      @child_group = @account.root_outcome_group.child_outcome_groups.create!(title: 'child group')
      @deleted_group = @account.root_outcome_group.child_outcome_groups.create!(title: 'deleted group')
      @deleted_group.workflow_state = 'deleted'
      @deleted_group.save!

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups",
        controller: 'outcome_groups_api', action: 'index', account_id: @account.id, format: 'json')
      expected_ids = [@account.root_outcome_group, @child_group].map(&:id).sort
      expect(json.map{|j| j['id']}.sort).to eq expected_ids
    end

  end

  describe "link_index" do
    before :once do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @group = @account.root_outcome_group
      @links = 3.times.map{ create_outcome }
    end

    it "should return active links" do
      link = @links.pop
      link.workflow_state = 'deleted'
      link.save!

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_group_links",
                      controller: 'outcome_groups_api',
                        action: 'link_index',
                        account_id: @account.id,
                        format: 'json')
      expected_outcome_ids = @links.map(&:content).map(&:id).sort
      expected_group_ids = @links.map(&:associated_asset).map(&:id).sort
      expect(json.map {|j| j['outcome']['id']}.sort).to eq expected_outcome_ids
      expect(json.map {|j| j['outcome_group']['id']}.sort).to eq expected_group_ids
    end

    it "should return links ordered by id when paginated" do
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_group_links?per_page=2",
                      controller: 'outcome_groups_api',
                      action: 'link_index',
                      account_id: @account.id,
                      per_page: "2",
                      format: 'json')

      # intentionally not manually sorting either the expected or returned:
      # - expected should be sorted by id because of creation time
      # - returned should be sorted by id because of pagination ordering
      expected_outcome_ids = @links.take(2).map(&:content).map(&:id)
      expect(json.map {|j| j['outcome']['id']}).to eq expected_outcome_ids
    end

    context "assessed trait on outcome link object" do
      let(:check_outcome) do
        ->(outcome, can_edit) do
          expect(outcome).to eq({
            "id" => @outcome.id,
            "vendor_guid" => @outcome.vendor_guid,
            "context_type" => @account.class.to_s,
            "context_id" => @account.id,
            "title" => @outcome.title.to_s,
            "display_name" => nil,
            "url" => api_v1_outcome_path(:id => @outcome.id),
            "can_edit" => can_edit,
            "has_updateable_rubrics" => false
          })
        end
      end

      let(:check_outcome_link) do
        ->(outcome_link, context, group, assessed, can_edit, can_unlink) do
          expect(outcome_link).to eq({
          "context_type" => context.class.to_s,
            "context_id" => context.id,
            "url" => polymorphic_path([:api_v1, context, :outcome_link], :id => group.id, :outcome_id => @outcome.id),
            "assessed" => assessed,
            "can_unlink" => can_unlink,
            "outcome_group" => {
              "id" => group.id,
              "title" => group.title,
              "vendor_guid" => group.vendor_guid,
              "url" => polymorphic_path([:api_v1, context, :outcome_group], :id => group.id),
              "subgroups_url" => polymorphic_path([:api_v1, context, :outcome_group_subgroups], :id => group.id),
              "outcomes_url" => polymorphic_path([:api_v1, context, :outcome_group_outcomes], :id => group.id),
              "can_edit" => can_edit
            }
          })
        end
      end

      it "outcome is not assessed" do
        expect(@outcome).not_to be_assessed

        json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_group_links",
                         controller: 'outcome_groups_api',
                         action: 'link_index',
                         account_id: @account.id,
                         format: 'json')

        check_outcome.call(json.last["outcome"], true)

        check_outcome_link.call(
          json.last.tap{|j| j.delete("outcome")},
          @account,
          @group,
          false,
          true,
          true
        )
      end

      it "outcome is assessed" do
        course_with_teacher(active_all: true)
        student_in_course(context: @course)
        @course.root_outcome_group.add_outcome(@outcome)
        expect(@outcome).not_to be_assessed(@course)

        course_with_teacher(active_all: true)
        student_in_course(context: @course)
        @course.root_outcome_group.add_outcome(@outcome)
        assess_with(@outcome, @course, @student)
        expect(@outcome).to be_assessed(@course)

        json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_group_links",
                         controller: 'outcome_groups_api',
                         action: 'link_index',
                         account_id: @account.id,
                         format: 'json')

        check_outcome.call(json.last["outcome"], false)

        # Account context should never be assessed
        check_outcome_link.call(
          json.last.tap{ |j| j.delete("outcome") },
          @account,
          @account.root_outcome_group,
          false,
          false,
          false
        )
      end
    end
  end

  describe "show" do
    describe "global context" do
      before :once do
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
        assert_status(200)
      end

      it "should 404 for non-global groups" do
        group = Account.default.root_outcome_group
        raw_api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')
        assert_status(404)
      end

      it "should 404 for deleted groups" do
        group = LearningOutcomeGroup.global_root_outcome_group.child_outcome_groups.create!(:title => 'subgroup')
        group.destroy
        raw_api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')
        assert_status(404)
      end

      it "should return the group json" do
        group = LearningOutcomeGroup.global_root_outcome_group
        json = api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')
        expect(json).to eq({
          "id" => group.id,
          "title" => group.title,
          "vendor_guid" => group.vendor_guid,
          "url" => polymorphic_path([:api_v1, :global, :outcome_group], :id => group.id),
          "can_edit" => true,
          "subgroups_url" => polymorphic_path([:api_v1, :global, :outcome_group_subgroups], :id => group.id),
          "outcomes_url" => polymorphic_path([:api_v1, :global, :outcome_group_outcomes], :id => group.id),
          "import_url" => polymorphic_path([:api_v1, :global, :outcome_group_import], :id => group.id),
          "context_id" => nil,
          "context_type" => nil,
          "description" => group.description
        })
      end

      it "should include parent_outcome_group if non-root" do
        parent_group = LearningOutcomeGroup.global_root_outcome_group
        group = parent_group.child_outcome_groups.create!(
          :title => 'Group Name',
          :description => 'Group Description',
          :vendor_guid => "vendorguid9001"
        )

        json = api_call(:get, "/api/v1/global/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :id => group.id.to_s,
                     :format => 'json')

        expect(json).to eq({
          "id" => group.id,
          "title" => group.title,
          "vendor_guid" => group.vendor_guid,
          "url" => polymorphic_path([:api_v1, :global, :outcome_group], :id => group.id),
          "can_edit" => true,
          "subgroups_url" => polymorphic_path([:api_v1, :global, :outcome_group_subgroups], :id => group.id),
          "outcomes_url" => polymorphic_path([:api_v1, :global, :outcome_group_outcomes], :id => group.id),
          "import_url" => polymorphic_path([:api_v1, :global, :outcome_group_import], :id => group.id),
          "parent_outcome_group" => {
            "id" => parent_group.id,
            "title" => parent_group.title,
            "vendor_guid" => parent_group.vendor_guid,
            "url" => polymorphic_path([:api_v1, :global, :outcome_group], :id => parent_group.id),
            "subgroups_url" => polymorphic_path([:api_v1, :global, :outcome_group_subgroups], :id => parent_group.id),
            "outcomes_url" => polymorphic_path([:api_v1, :global, :outcome_group_outcomes], :id => parent_group.id),
            "can_edit" => true
          },
          "context_id" => nil,
          "context_type" => nil,
          "description" => group.description
        })
      end
    end

    describe "non-global context" do
      before :once do
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
        assert_status(404)
      end

      it "should include the account in the group json" do
        group = @account.root_outcome_group
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{group.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'show',
                     :account_id => @account.id.to_s,
                     :id => group.id.to_s,
                     :format => 'json')
        expect(json).to eq({
          "id" => group.id,
          "title" => group.title,
          "vendor_guid" => group.vendor_guid,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => group.id),
          "can_edit" => true,
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => group.id),
          "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => group.id),
          "context_id" => @account.id,
          "context_type" => "Account",
          "description" => group.description
        })
      end
    end
  end

  describe "update" do
    before :once do
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
      assert_status(401)
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
      assert_status(401)
    end

    it "should fail for root groups" do
      @group = @root_group
      raw_api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'update',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      assert_status(400)
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
      expect(@group.title).to eq "New Title"
      expect(@group.description).to eq "New Description"
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
      expect(@group.title).to eq "New Title"
      expect(@group.description).to eq "Original Description"
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
      expect(groupC.parent_outcome_group).to eq groupB
      expect(groupA.child_outcome_groups.reload).to eq []
      expect(groupB.child_outcome_groups.reload).to eq [groupC]
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
      assert_status(400)
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
      assert_status(400)
    end

    it "should return the updated group json" do
      json = api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               { :controller => 'outcome_groups_api',
                 :action => 'update',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "New Title",
                 :description => "New Description",
                 :vendor_guid => "vendorguid9002"
               })

      expect(json).to eq({
        "id" => @group.id,
        "vendor_guid" => "vendorguid9002",
        "title" => "New Title",
        "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
        "can_edit" => true,
        "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
        "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
        "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => @group.id),
        "parent_outcome_group" => {
          "id" => @root_group.id,
          "title" => @root_group.title,
          "vendor_guid" => @root_group.vendor_guid,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @root_group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @root_group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @root_group.id),
          "can_edit" => true
        },
        "context_id" => @account.id,
        "context_type" => "Account",
        "description" => "New Description"
      })
    end
  end

  describe "destroy" do
    before :once do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @root_group = @account.root_outcome_group
      @group = @root_group.child_outcome_groups.create!(:title => 'subgroup', :vendor_guid => "vendorguid9001")
    end

    it "should require permission" do
      revoke_permission(@account_user, :manage_outcomes)
      raw_api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'destroy',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      assert_status(401)
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
      assert_status(401)
    end

    it "should fail for root groups" do
      @group = @root_group
      raw_api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'destroy',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      assert_status(400)
    end

    it "should delete the group" do
      api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               :controller => 'outcome_groups_api',
               :action => 'destroy',
               :account_id => @account.id.to_s,
               :id => @group.id.to_s,
               :format => 'json')

      @group.reload
      expect(@group).to be_deleted
    end

    it "should return json of the deleted group" do
      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}",
               :controller => 'outcome_groups_api',
               :action => 'destroy',
               :account_id => @account.id.to_s,
               :id => @group.id.to_s,
               :format => 'json')

      expect(json).to eq({
        "id" => @group.id,
        "vendor_guid" => @group.vendor_guid,
        "title" => 'subgroup',
        "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
        "can_edit" => true,
        "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
        "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
        "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => @group.id),
        "parent_outcome_group" => {
          "id" => @root_group.id,
          "title" => @root_group.title,
          "vendor_guid" => @root_group.vendor_guid,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @root_group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @root_group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @root_group.id),
          "can_edit" => true
        },
        "context_id" => @account.id,
        "context_type" => "Account",
        "description" => nil
      })
    end
  end

  describe "outcomes" do
    before :once do
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
      expect(response).to be_success
    end

    it "should return the outcomes linked into the group" do
      3.times{ create_outcome }
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      expect(json.sort_by{ |link| link['outcome']['id'] }).to eq(@account.created_learning_outcomes.map do |outcome|
        {
          "context_type" => "Account",
          "context_id" => @account.id,
          "url" => polymorphic_path([:api_v1, @account, :outcome_link], :id => @group.id, :outcome_id => outcome.id),
          "assessed" => false,
          "can_unlink" => true,
          "outcome_group" => {
            "id" => @group.id,
            "title" => @group.title,
            "vendor_guid" => @group.vendor_guid,
            "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
            "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
            "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
            "can_edit" => true
          },
          "outcome" => {
            "id" => outcome.id,
            "vendor_guid" => outcome.vendor_guid,
            "context_type" => "Account",
            "context_id" => @account.id,
            "title" => outcome.title,
            "display_name" => nil,
            "url" => api_v1_outcome_path(:id => outcome.id),
            "can_edit" => true,
            "has_updateable_rubrics" => false
          }
        }
      end.sort_by{ |link| link['outcome']['id'] })
    end

    it "should return additional information when 'full' arg passed" do
      description = "some really cool description"
      create_outcome(:description => description)

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_style => "full",
                   :format => 'json')

      expect(json.first['outcome']['description']).to eq description
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

      expect(json.size).to eq 1
      expect(json.first['outcome']['id']).to eq @outcome1.id
    end

    it "should order links by outcome title" do
      @links = ["B", "A", "C"].map{ |title| create_outcome(:title => title) }
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      expect(json.map{ |link| link['outcome']['id'] }).to eq(
        [1, 0, 2].map{ |i| @links[i].content_id }
      )
    end

    it "should paginate the links" do
      links = 5.times.map { |i| create_outcome(:title => "#{i}".object_id) }

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes?per_page=2",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json',
                   :per_page => '2')
      expect(json.size).to eql 2
      expect(response.headers['Link']).to match(%r{<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=2.*>; rel="next",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=1.*>; rel="first",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=3.*>; rel="last"})

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes?per_page=2&page=3",
                   :controller => 'outcome_groups_api',
                   :action => 'outcomes',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json',
                   :per_page => '2',
                   :page => '3')
      expect(json.size).to eql 1
      expect(response.headers['Link']).to match(%r{<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=2.*>; rel="prev",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=1.*>; rel="first",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes\?.*page=3.*>; rel="last"})
    end

    context "assessed trait on outcome link object" do
      let(:check_outcome) do
        ->(outcome) do
          expect(outcome).to eq({
            "id" => @outcome.id,
            "vendor_guid" => @outcome.vendor_guid,
            "context_type" => @account.class.to_s,
            "context_id" => @account.id,
            "title" => @outcome.title.to_s,
            "display_name" => nil,
            "url" => api_v1_outcome_path(:id => @outcome.id),
            "can_edit" => !LearningOutcome.find(@outcome.id).assessed?,
            "has_updateable_rubrics" => @outcome.updateable_rubrics?
          })
        end
      end

      let(:check_outcome_link) do
        ->(outcome_link, context, group, assessed, can_unlink) do
          expect(outcome_link).to eq({
          "context_type" => context.class.to_s,
            "context_id" => context.id,
            "url" => polymorphic_path([:api_v1, context, :outcome_link], :id => group.id, :outcome_id => @outcome.id),
            "assessed" => assessed,
            "can_unlink" => can_unlink,
            "outcome_group" => {
              "id" => group.id,
              "title" => group.title,
              "vendor_guid" => group.vendor_guid,
              "url" => polymorphic_path([:api_v1, context, :outcome_group], :id => group.id),
              "subgroups_url" => polymorphic_path([:api_v1, context, :outcome_group_subgroups], :id => group.id),
              "outcomes_url" => polymorphic_path([:api_v1, context, :outcome_group_outcomes], :id => group.id),
              "can_edit" => !assessed
            }
          })
        end
      end

      it "outcome is not assessed" do
        create_outcome(:title => "Un outcome")
        expect(@outcome).not_to be_assessed

        json = api_call(
          :get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
          :controller => 'outcome_groups_api',
          :action => 'outcomes',
          :account_id => @account.id.to_s,
          :id => @group.id.to_s,
          :format => 'json'
        )

        check_outcome.call(json.first["outcome"])
        check_outcome_link.call(json.first.tap{|j| j.delete("outcome")}, @account, @group, false, true)
      end

      it "outcome is assessed" do
        create_outcome(:title => "Un outcome")

        course_with_teacher(active_all: true)
        student_in_course(context: @course)
        @course.root_outcome_group.add_outcome(@outcome)
        expect(@outcome).not_to be_assessed(@course)

        course_with_teacher(active_all: true)
        student_in_course(context: @course)
        @course.root_outcome_group.add_outcome(@outcome)
        assess_with(@outcome, @course, @student)
        expect(@outcome).to be_assessed

        json = api_call(
          :get, "/api/v1/courses/#{@course.id}/outcome_groups/#{@course.root_outcome_group.id}/outcomes",
          :controller => 'outcome_groups_api',
          :action => 'outcomes',
          :course_id => @course.id.to_s,
          :id => @course.root_outcome_group.id.to_s,
          :format => 'json'
        )

        check_outcome.call(json.first["outcome"])

        check_outcome_link.call(
          json.first.tap{ |j| j.delete("outcome") },
          @course,
          @course.root_outcome_group,
          true,
          false
        )
      end

      it "should return can_unlink of 'false' if it cannot unlink" do
        create_outcome(:title => "Un outcome")

        course_with_teacher(active_all: true)
        @course.root_outcome_group.add_outcome(@outcome)

        aqb = @course.assessment_question_banks.create!
        @outcome.align(aqb, @course, :mastery_type => "none")

        json = api_call(
          :get, "/api/v1/courses/#{@course.id}/outcome_groups/#{@course.root_outcome_group.id}/outcomes",
          :controller => 'outcome_groups_api',
          :action => 'outcomes',
          :course_id => @course.id.to_s,
          :id => @course.root_outcome_group.id.to_s,
          :format => 'json'
        )

        check_outcome_link.call(
          json.first.tap{ |j| j.delete("outcome") },
          @course,
          @course.root_outcome_group,
          false,
          false
        )
      end
    end
  end

  describe "link existing" do
    context "account" do
      before :once do
        @account = Account.default
        @account_user = @user.account_users.create(:account => @account)
        @group = @account.root_outcome_group
        @outcome = LearningOutcome.global.create!(:title => 'subgroup', :vendor_guid => "vendorguid9000")
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
        assert_status(401)
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
        assert_status(401)
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
        assert_status(400)
      end

      it "should link the outcome into the group" do
        expect(@group.child_outcome_links).to be_empty
        api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'link',
                     :account_id => @account.id.to_s,
                     :id => @group.id.to_s,
                     :outcome_id => @outcome.id.to_s,
                     :format => 'json')
        expect(@group.child_outcome_links.reload.size).to eq 1
        expect(@group.child_outcome_links.first.content).to eq @outcome
      end

      context 'moving outcome link to another group' do
        def sub_group_with_outcome
          expect(@group.child_outcome_links).to be_empty
          sub_group = @account.learning_outcome_groups.create!(title: 'some lonely sub group')
          sub_group.add_outcome(@outcome)
          expect(sub_group.child_outcome_links.reload.size).to eq 1
          expect(sub_group.child_outcome_links.first.content).to eq @outcome
          sub_group
        end

        it "should re-use an old link if move_from is included" do
          sub_group = sub_group_with_outcome
          api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                       controller: 'outcome_groups_api',
                       action: 'link',
                       account_id: @account.id.to_s,
                       id: @group.id.to_s,
                       outcome_id: @outcome.id.to_s,
                       move_from: sub_group.id.to_s,
                       format: 'json')
          expect(@group.child_outcome_links.reload.size).to eq 1
          expect(@group.child_outcome_links.first.content).to eq @outcome
          expect(sub_group.child_outcome_links.reload).to be_empty
        end

        it "should not re-use an old link if move_from is omitted" do
          sub_group = sub_group_with_outcome
          api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                       controller: 'outcome_groups_api',
                       action: 'link',
                       account_id: @account.id.to_s,
                       id: @group.id.to_s,
                       outcome_id: @outcome.id.to_s,
                       format: 'json')
          expect(@group.child_outcome_links.reload.size).to eq 1
          expect(@group.child_outcome_links.first.content).to eq @outcome
          expect(sub_group.child_outcome_links.reload.size).to eq 1
          expect(sub_group.child_outcome_links.first.content).to eq @outcome
        end
      end

      it "should return json of the new link" do
        json = api_call(:put, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                     :controller => 'outcome_groups_api',
                     :action => 'link',
                     :account_id => @account.id.to_s,
                     :id => @group.id.to_s,
                     :outcome_id => @outcome.id.to_s,
                     :format => 'json')
        expect(json).to eq({
          "context_type" => "Account",
          "context_id" => @account.id,
          "url" => polymorphic_path([:api_v1, @account, :outcome_link], :id => @group.id, :outcome_id => @outcome.id),
          "assessed" => false,
          "can_unlink" => true,
          "outcome_group" => {
            "id" => @group.id,
            "title" => @group.title,
            "vendor_guid" => @group.vendor_guid,
            "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
            "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
            "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
            "can_edit" => true
          },
          "outcome" => {
            "id" => @outcome.id,
            "vendor_guid" => @outcome.vendor_guid,
            "context_type" => nil,
            "context_id" => nil,
            "title" => @outcome.title,
            "display_name" => nil,
            "url" => api_v1_outcome_path(:id => @outcome.id),
            "can_edit" => false,
            "has_updateable_rubrics" => false
          }
        })
      end
    end
  end

  describe "link new" do
    before :once do
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
      assert_status(400)
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
                 :display_name => "Friendly Name",
                 :description => "Description of my outcome",
                 :mastery_points => 5,
                 :ratings => [
                   { :points => 5, :description => "Exceeds Expectations" },
                   { :points => 3, :description => "Meets Expectations" },
                   { :points => 0, :description => "Does Not Meet Expectations" }
                 ]
               })
      expect(LearningOutcome.active.count).to eq 1
      @outcome = LearningOutcome.active.first
      expect(@outcome.title).to eq "My Outcome"
      expect(@outcome.display_name).to eq "Friendly Name"
      expect(@outcome.description).to eq "Description of my outcome"
      expect(@outcome.data[:rubric_criterion]).to eq({
        :description => 'My Outcome',
        :mastery_points => 5,
        :points_possible => 5,
        :ratings => [
          { :points => 5, :description => "Exceeds Expectations" },
          { :points => 3, :description => "Meets Expectations" },
          { :points => 0, :description => "Does Not Meet Expectations" }
        ]
      })
    end

    it "should create a new outcome with default values for mastery calculation" do
      prev_count = LearningOutcome.active.count
      json = api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
               { :controller => 'outcome_groups_api',
                 :action => 'link',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "My Outcome",
                 :display_name => "Friendly Name",
                 :description => "Description of my outcome",
                 :mastery_points => 5,
                 :ratings => [
                   { :points => 5, :description => "Exceeds Expectations" },
                   { :points => 3, :description => "Meets Expectations" },
                   { :points => 0, :description => "Does Not Meet Expectations" }
                 ]
      })

      expect(LearningOutcome.active.count).to eq(prev_count + 1)
      @outcome = LearningOutcome.find(json["outcome"]["id"])
      expect(@outcome.title).to eq "My Outcome"
      expect(@outcome.display_name).to eq "Friendly Name"
      expect(@outcome.description).to eq "Description of my outcome"
      expect(@outcome.data[:rubric_criterion]).to eq({
        :description => 'My Outcome',
        :mastery_points => 5,
        :points_possible => 5,
        :ratings => [
          { :points => 5, :description => "Exceeds Expectations" },
          { :points => 3, :description => "Meets Expectations" },
          { :points => 0, :description => "Does Not Meet Expectations" }
        ]
      })
      expect(@outcome.calculation_method).to eq("highest")
      expect(@outcome.calculation_int).to be_nil
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
      expect(@group.child_outcome_links.count).to eq 1
      expect(@group.child_outcome_links.first.content).to eq @outcome
    end

    context "creating with calculation options specified" do
      it "should create a new outcome with calculation options specified" do
        LearningOutcome.update_all(:workflow_state => 'deleted')
        api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                 { :controller => 'outcome_groups_api',
                   :action => 'link',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json' },
                 { :title => "My Outcome",
                   :display_name => "Friendly Name",
                   :description => "Description of my outcome",
                   :mastery_points => 5,
                   :ratings => [
                     { :points => 5, :description => "Exceeds Expectations" },
                     { :points => 3, :description => "Meets Expectations" },
                     { :points => 0, :description => "Does Not Meet Expectations" }
                   ],
                   :calculation_method => 'n_mastery',
                   :calculation_int => 4,
                 })
        expect(LearningOutcome.active.count).to eq 1
        @outcome = LearningOutcome.active.first
        expect(@outcome.title).to eq "My Outcome"
        expect(@outcome.display_name).to eq "Friendly Name"
        expect(@outcome.description).to eq "Description of my outcome"
        expect(@outcome.data[:rubric_criterion]).to eq({
          :description => 'My Outcome',
          :mastery_points => 5,
          :points_possible => 5,
          :ratings => [
            { :points => 5, :description => "Exceeds Expectations" },
            { :points => 3, :description => "Meets Expectations" },
            { :points => 0, :description => "Does Not Meet Expectations" }
          ]
        })
        expect(@outcome.calculation_method).to eq("n_mastery")
        expect(@outcome.calculation_int).to eq(4)
      end

      it "should fail (400) to create a new outcome with illegal calculation options" do
        LearningOutcome.update_all(:workflow_state => 'deleted')
        json = api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                 { :controller => 'outcome_groups_api',
                   :action => 'link',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json' },
                 { :title => "My Outcome",
                   :display_name => "Friendly Name",
                   :description => "Description of my outcome",
                   :mastery_points => 5,
                   :ratings => [
                     { :points => 5, :description => "Exceeds Expectations" },
                     { :points => 3, :description => "Meets Expectations" },
                     { :points => 0, :description => "Does Not Meet Expectations" }
                   ],
                   :calculation_method => 'foo bar baz qux',
                   :calculation_int => 1500,
                 },
                 {},
                 { :expected_status => 400 })
        expect(LearningOutcome.active.count).to eq 0
        expect(json).not_to be_nil
        expect(json["errors"]).not_to be_nil
        expect(json["errors"]["calculation_method"]).not_to be_nil
        expect(json["errors"]["calculation_method"][0]).not_to be_nil
        expect(json["errors"]["calculation_method"][0]["message"]).not_to be_nil
        expect(json["errors"]["calculation_method"][0]["message"]).to include("calculation_method must be one of")
      end

      context "should fail (400) to create a new outcome with an illegal calculation_int" do
        methods = [
          'decaying_average',
          'n_mastery',
          'highest',
          'latest'
        ]

        methods.each do |method|
          it "should fail (400) to create a new outcome with an illegal calculation_int" do
            LearningOutcome.update_all(:workflow_state => 'deleted')
            json = api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes",
                     { :controller => 'outcome_groups_api',
                       :action => 'link',
                       :account_id => @account.id.to_s,
                       :id => @group.id.to_s,
                       :format => 'json' },
                     { :title => "My Outcome",
                       :display_name => "Friendly Name",
                       :description => "Description of my outcome",
                       :mastery_points => 5,
                       :ratings => [
                         { :points => 5, :description => "Exceeds Expectations" },
                         { :points => 3, :description => "Meets Expectations" },
                         { :points => 0, :description => "Does Not Meet Expectations" }
                       ],
                       :calculation_method => method,
                       :calculation_int => 1500,
                     },
                     {},
                     { :expected_status => 400 })
            expect(LearningOutcome.active.count).to eq 0
            expect(json).not_to be_nil
            expect(json["errors"]).not_to be_nil
            expect(json["errors"]["calculation_int"]).not_to be_nil
            expect(json["errors"]["calculation_int"][0]).not_to be_nil
            expect(json["errors"]["calculation_int"][0]["message"]).not_to be_nil
            if %w[highest latest].include?(method)
              expect(json["errors"]["calculation_int"][0]["message"]).to include("A calculation value is not used with this calculation method")
            else
              expect(json["errors"]["calculation_int"][0]["message"]).to include("not a valid value for this calculation method")
            end
          end
        end
      end
    end
  end

  describe "unlink" do
    before :once do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @group = @account.root_outcome_group
      @outcome = LearningOutcome.global.create!(:title => 'outcome', :vendor_guid => "vendorguid9000")
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
      assert_status(401)
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
      assert_status(401)
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
      assert_status(404)
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
      assert_status(400)
      parsed_body = JSON.parse( response.body )
      expect(parsed_body[ 'message' ]).to match /link is the last link/i
    end

    it "should unlink the outcome from the group" do
      expect(@group.child_outcome_links.active.size).to eq 1
      api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'unlink',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      expect(@group.child_outcome_links.active.size).to eq 0
    end

    it "should return json of the removed link" do
      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/outcomes/#{@outcome.id}",
                   :controller => 'outcome_groups_api',
                   :action => 'unlink',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :outcome_id => @outcome.id.to_s,
                   :format => 'json')
      expect(json).to eq({
        "context_type" => "Account",
        "context_id" => @account.id,
        "url" => polymorphic_path([:api_v1, @account, :outcome_link], :id => @group.id, :outcome_id => @outcome.id),
        "assessed" => false,
        "outcome_group" => {
          "id" => @group.id,
          "title" => @group.title,
          "vendor_guid" => @group.vendor_guid,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
          "can_edit" => true
        },
        "outcome" => {
          "id" => @outcome.id,
          "vendor_guid" => @outcome.vendor_guid,
          "context_type" => nil,
          "context_id" => nil,
          "display_name" => nil,
          "title" => @outcome.title,
          "url" => api_v1_outcome_path(:id => @outcome.id),
          "can_edit" => false,
          "has_updateable_rubrics" => false
        }
      })
    end
  end

  describe "subgroups" do
    before :once do
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
      expect(response).to be_success
    end

    def create_subgroup(opts={})
      group = opts.delete(:group) || @group
      group.child_outcome_groups.create!({:title => 'subgroup', :vendor_guid => 'blahblah'}.merge(opts))
    end

    it "should return the subgroups under the group" do
      3.times{ create_subgroup }
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      expect(json.sort_by{ |subgroup| subgroup['id'] }).to eq(@group.child_outcome_groups.map do |subgroup|
        {
          "id" => subgroup.id,
          "title" => subgroup.title,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => subgroup.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => subgroup.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => subgroup.id),
          "vendor_guid" => subgroup.vendor_guid,
          "can_edit" => true
        }
      end.sort_by{ |subgroup| subgroup['id'] })
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

      expect(json.size).to eq 1
      expect(json.first['id']).to eq @subgroup1.id
    end

    it "should order subgroups by title" do
      @subgroups = ["B", "A", "C"].map{ |title| create_subgroup(:title => title) }
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json')
      expect(json.map{ |link| link['id'] }).to eq(
        [1, 0, 2].map{ |i| @subgroups[i].id }
      )
    end

    it "should paginate the subgroups" do
      subgroups = 5.times.map { |i| create_subgroup }

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups?per_page=2",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json',
                   :per_page => '2')
      expect(json.size).to eql 2
      expect(response.headers['Link']).to match(%r{<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=2.*>; rel="next",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=1.*>; rel="first",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=3.*>; rel="last"})

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups?per_page=2&page=3",
                   :controller => 'outcome_groups_api',
                   :action => 'subgroups',
                   :account_id => @account.id.to_s,
                   :id => @group.id.to_s,
                   :format => 'json',
                   :per_page => '2',
                   :page => '3')
      expect(json.size).to eql 1
      expect(response.headers['Link']).to match(%r{<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=2.*>; rel="prev",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=1.*>; rel="first",<.*/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups\?.*page=3.*>; rel="last"})
    end
  end

  describe "create" do
    before :once do
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
      assert_status(401)
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
      assert_status(401)
    end

    it "should create a new outcome group" do
      expect(@group.child_outcome_groups.size).to eq 0
      api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
               { :controller => 'outcome_groups_api',
                 :action => 'create',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "My Subgroup",
                 :description => "Description of my subgroup" })
      expect(@group.child_outcome_groups.active.size).to eq 1
      @subgroup = @group.child_outcome_groups.active.first
      expect(@subgroup.title).to eq "My Subgroup"
      expect(@subgroup.description).to eq "Description of my subgroup"
    end

    it "should return json of the new subgroup" do
      json = api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@group.id}/subgroups",
               { :controller => 'outcome_groups_api',
                 :action => 'create',
                 :account_id => @account.id.to_s,
                 :id => @group.id.to_s,
                 :format => 'json' },
               { :title => "My Subgroup",
                 :description => "Description of my subgroup",
                 :vendor_guid => "vendorguid9000"
               })
      @subgroup = @group.child_outcome_groups.active.first
      expect(json).to eq({
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
          "vendor_guid" => @group.vendor_guid,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @group.id),
          "can_edit" => true
        },
        "context_id" => @account.id,
        "context_type" => "Account",
        "vendor_guid" => "vendorguid9000",
        "description" => @subgroup.description
      })
    end
  end

  describe "import" do
    before :once do
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @source_group = LearningOutcomeGroup.global_root_outcome_group.child_outcome_groups.create!(
        :title => "Source Group",
        :description => "Description of source group",
        :vendor_guid => "vendorguid9000"
      )
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
      assert_status(401)
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
      assert_status(401)
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
      assert_status(400)
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
      assert_status(400)
    end

    it "should create a new outcome group" do
      expect(@target_group.child_outcome_groups.size).to eq 0
      api_call(:post, "/api/v1/accounts/#{@account.id}/outcome_groups/#{@target_group.id}/import",
                   { :controller => 'outcome_groups_api',
                     :action => 'import',
                     :account_id => @account.id.to_s,
                     :id => @target_group.id.to_s,
                     :format => 'json' },
                   { :source_outcome_group_id => @source_group.id.to_s })
      expect(@target_group.child_outcome_groups.active.size).to eq 1
      @subgroup = @target_group.child_outcome_groups.active.first
      expect(@subgroup.title).to eq @source_group.title
      expect(@subgroup.description).to eq @source_group.description
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
      expect(json).to eq({
        "id" => @subgroup.id,
        "title" => @source_group.title,
        "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @subgroup.id),
        "can_edit" => true,
        "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @subgroup.id),
        "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @subgroup.id),
        "import_url" => polymorphic_path([:api_v1, @account, :outcome_group_import], :id => @subgroup.id),
        "parent_outcome_group" => {
          "id" => @target_group.id,
          "title" => @target_group.title,
          "vendor_guid" => @target_group.vendor_guid,
          "url" => polymorphic_path([:api_v1, @account, :outcome_group], :id => @target_group.id),
          "subgroups_url" => polymorphic_path([:api_v1, @account, :outcome_group_subgroups], :id => @target_group.id),
          "outcomes_url" => polymorphic_path([:api_v1, @account, :outcome_group_outcomes], :id => @target_group.id),
          "can_edit" => true
        },
        "context_id" => @account.id,
        "context_type" => "Account",
        "vendor_guid" => @source_group.vendor_guid,
        "description" => @source_group.description
      })
    end
  end
end
