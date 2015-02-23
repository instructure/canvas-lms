
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

describe "Outcomes API", type: :request do
  def context_outcome(context)
    @outcome_group ||= context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(:title => 'outcome')
    @outcome_group.add_outcome(@outcome)
  end

  def course_outcome
    context_outcome(@course)
  end

  def account_outcome
    context_outcome(@account)
  end

  def outcome_json(outcome=@outcome, presets={})
    retval = {
      "id"          => presets[:id]           || outcome.id,
      "context_id"  => presets[:context_id]   || outcome.context_id,
      "context_type"=> presets[:context_type] || outcome.context_type,
      "title"       => presets[:title]        || outcome.title,
      "display_name"=> presets[:display_name] || outcome.display_name,
      "url"         => presets[:url]          || api_v1_outcome_path(:id => outcome.id),
      "vendor_guid" => presets[:vendor_guid]  || outcome.vendor_guid,
      "can_edit"    => presets[:can_edit]     || true,
      "description" => presets[:description]  || outcome.description
    }

    if criterion = outcome.data && outcome.data[:rubric_criterion]
      retval["calculation_method"] = presets[:calculation_method] || outcome.calculation_method
      retval["points_possible"]    = presets[:points_possible]    || criterion[:points_possible].to_i
      retval["mastery_points"]     = presets[:mastery_points]     || criterion[:mastery_points].to_i
      retval["ratings"]            = presets[:ratings]            || criterion[:ratings].map{ |d| d.stringify_keys }

      if outcome.calculation_method == "decaying_average" || outcome.calculation_method == "n_mastery"
        retval["calculation_int"] = presets[:calculation_int] || outcome.calculation_int
      end
    end

    return retval
  end

  def assess_outcome(outcome=@outcome)
    @rubric = Rubric.create!(:context => @course)
    @rubric.data = [
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
    @rubric.save!
    @e = @course.enroll_student(@student)
    @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
    @assignment.reload
    @submission = @assignment.grade_student(@student, :grade => "10").first
    @assessment = @a.assess({
      :user => @student,
      :assessor => @teacher,
      :artifact => @submission,
      :assessment => {
        :assessment_type => 'grading',
        :criterion_1 => {
          :points => 2,
          :comments => "cool, yo"
        }
      }
    })
    @result = outcome.learning_outcome_results.first
    @assessment = @a.assess({
      :user => @student,
      :assessor => @teacher,
      :artifact => @submission,
      :assessment => {
        :assessment_type => 'grading',
        :criterion_1 => {
          :points => 3,
          :comments => "cool, yo"
        }
      }
    })
    @result.reload
    @rubric.reload
  end

  def outcomes_json(outcomes=@outcomes, presets={})
    outcomes.map { |o| outcome_json(o) }
  end

  context "account outcomes" do
    before :once do
      user_with_pseudonym(:active_all => true)
      @account = Account.default
      @account_user = @user.account_users.create(:account => @account)
      @outcome = @account.created_learning_outcomes.create!(
        :title => "My Outcome",
        :description => "Description of my outcome",
        :vendor_guid => "vendorguid9000"
      )
    end

    before :each do
      Pseudonym.any_instance.stubs(:works_for_account?).returns(true)
    end

    def revoke_permission(account_user, permission)
      RoleOverride.manage_role_override(account_user.account, account_user.role, permission.to_s, :override => false)
    end

    describe "show" do
      it "should not require manage permission" do
        revoke_permission(@account_user, :manage_outcomes)
        raw_api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                     :controller => 'outcomes_api',
                     :action => 'show',
                     :id => @outcome.id.to_s,
                     :format => 'json')
        expect(response).to be_success
      end

      it "should require read permission" do
        # new user, doesn't have a tie to the account
        user_with_pseudonym(:account => Account.create!, :active_all => true)
        raw_api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                     :controller => 'outcomes_api',
                     :action => 'show',
                     :id => @outcome.id.to_s,
                     :format => 'json')
        assert_status(401)
      end

      it "should not require any permission for global outcomes" do
        user_with_pseudonym(:account => Account.create!, :active_all => true)
        @outcome = LearningOutcome.create!(:title => "My Outcome")
        raw_api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                     :controller => 'outcomes_api',
                     :action => 'show',
                     :id => @outcome.id.to_s,
                     :format => 'json')
        expect(response).to be_success
      end

      it "should still require a user for global outcomes" do
        @outcome = LearningOutcome.create!(:title => "My Outcome")
        @user = nil
        raw_api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                     :controller => 'outcomes_api',
                     :action => 'show',
                     :id => @outcome.id.to_s,
                     :format => 'json')
        assert_status(401)
      end

      it "should 404 for deleted outcomes" do
        @outcome.destroy
        raw_api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                     :controller => 'outcomes_api',
                     :action => 'show',
                     :id => @outcome.id.to_s,
                     :format => 'json')
        assert_status(404)
      end

      it "should return the outcome json" do
        json = api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                     :controller => 'outcomes_api',
                     :action => 'show',
                     :id => @outcome.id.to_s,
                     :format => 'json')
        expect(json).to eq({
          "id" => @outcome.id,
          "context_id" => @account.id,
          "context_type" => "Account",
          "title" => @outcome.title,
          "display_name" => nil,
          "url" => api_v1_outcome_path(:id => @outcome.id),
          "vendor_guid" => "vendorguid9000",
          "can_edit" => true,
          "description" => @outcome.description
        })
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

        expect(json).to eq({
          "id" => @outcome.id,
          "context_id" => @account.id,
          "context_type" => "Account",
          "title" => @outcome.title,
          "display_name" => nil,
          "url" => api_v1_outcome_path(:id => @outcome.id),
          "vendor_guid" => "vendorguid9000",
          "can_edit" => true,
          "description" => @outcome.description,
          "points_possible" => 5,
          "mastery_points" => 3,
          "calculation_method" => "highest",
          "ratings" => [
            { "points" => 5, "description" => "Exceeds Expectations" },
            { "points" => 3, "description" => "Meets Expectations" },
            { "points" => 0, "description" => "Does Not Meet Expectations" }
          ]
        })
      end

      it "should report calculation methods that are nil as highest so old outcomes continue to behave the same before we added a calculation_method" do
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

        # The order here is intentional.  We don't want to trigger the before_save callback on LearningOutcome
        # because it will take away our nil calculation_method.  The nil is required in order to
        # simulate pre-existing learning outcome records that have nil calculation_methods
        @outcome.update_column(:calculation_method, nil)

        json = api_call(:get, "/api/v1/outcomes/#{@outcome.id}",
                     :controller => 'outcomes_api',
                     :action => 'show',
                     :id => @outcome.id.to_s,
                     :format => 'json')
        expect(json).to eq(outcome_json(@outcome, { :calculation_method => "highest", :can_edit => true }))
      end
    end

    describe "update" do
      it "should require manage permission" do
        revoke_permission(@account_user, :manage_outcomes)
        raw_api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                     :controller => 'outcomes_api',
                     :action => 'update',
                     :id => @outcome.id.to_s,
                     :format => 'json')
        assert_status(401)
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
        assert_status(401)
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
        assert_status(400)
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
        expect(@outcome.title).to eq "Updated Outcome"
        expect(@outcome.description).to eq "Description of updated outcome"
        expect(@outcome.data[:rubric_criterion]).to eq({
          :description => 'Updated Outcome',
          :mastery_points => 5,
          :points_possible => 10,
          :ratings => [
            { :points => 10, :description => "Exceeds Expectations" },
            { :points => 5, :description => "Meets Expectations" },
            { :points => 0, :description => "Does Not Meet Expectations" }
          ]
        })
      end

      it "should leave alone fields not provided" do
        api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                 { :controller => 'outcomes_api',
                   :action => 'update',
                   :id => @outcome.id.to_s,
                   :format => 'json' },
                 { :title => "New Title" })

        @outcome.reload
        expect(@outcome.title).to eq "New Title"
        expect(@outcome.description).to eq "Description of my outcome"
      end

      it "should return the updated outcome json" do
        json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                 { :controller => 'outcomes_api',
                   :action => 'update',
                   :id => @outcome.id.to_s,
                   :format => 'json' },
                 { :title => "New Title",
                   :description => "New Description",
                   :vendor_guid => "vendorguid9000"})

        expect(json).to eq({
          "id" => @outcome.id,
          "context_id" => @account.id,
          "context_type" => "Account",
          "vendor_guid" => "vendorguid9000",
          "title" => "New Title",
          "display_name" => nil,
          "url" => api_v1_outcome_path(:id => @outcome.id),
          "can_edit" => true,
          "description" => "New Description"
        })
      end

      context "calculation options" do
        before :once do
          # set criterion so we get back our calculation_method
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
        end

        it "should allow updating calculation method" do
          # Check pre-condition to make sure we're really updating with our API call
          expect(@outcome.calculation_method).not_to eq('n_mastery')

          json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                   { :controller => 'outcomes_api',
                     :action => 'update',
                     :id => @outcome.id.to_s,
                     :format => 'json' },
                   { :title => "New Title",
                     :description => "New Description",
                     :vendor_guid => "vendorguid9000",
                     :calculation_method => "n_mastery",
                     :calculation_int => "3" })
          @outcome.reload
          expect(json).to eq(outcome_json)
          expect(@outcome.calculation_method).to eq('n_mastery')
        end

        it "should allow updating the calculation int" do
          # Check pre-condition to make sure we're really updating with our API call
          expect(@outcome.calculation_int).not_to eq(3)

          json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                   { :controller => 'outcomes_api',
                     :action => 'update',
                     :id => @outcome.id.to_s,
                     :format => 'json' },
                   { :title => "New Title",
                     :description => "New Description",
                     :vendor_guid => "vendorguid9000",
                     :calculation_method => "n_mastery",
                     :calculation_int => 3 })

          expect(json["calculation_int"]).to eql(3)
          expect(json["calculation_method"]).to eql('n_mastery')

          @outcome.reload
          expect(json).to eq(outcome_json)
          expect(@outcome.calculation_method).to eql('n_mastery')
          expect(@outcome.calculation_int).to eql(3)
        end

        context "should not allow updating the calculation_int to an illegal value for the calculation_method" do
          before :once do
            # outcome calculation_method needs to be something not used as a test case
            @outcome.calculation_method = 'decaying_average'
            @outcome.calculation_int = 75
            @outcome.save!
          end

          method_to_int = {
            "decaying_average" => { good: 67, bad: 125 },
            "n_mastery" => { good: 4, bad: 29 },
            "highest" => { good: nil, bad: 4 },
            "latest" => { good: nil, bad: 79 },
          }

          method_to_int.each do |method, int|
            it "should not allow updating the calculation_int to an illegal value for the calculation_method '#{method}'" do
              expect {
                api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                       { :controller => 'outcomes_api',
                         :action => 'update',
                         :id => @outcome.id.to_s,
                         :format => 'json' },
                       { :title => "New Title",
                         :description => "New Description",
                         :vendor_guid => "vendorguid9000",
                         :calculation_method => method,
                         :calculation_int => int[:good] })
                @outcome.reload
              }.to change{@outcome.calculation_int}.to(int[:good])

              expect {
                api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                       { :controller => 'outcomes_api',
                         :action => 'update',
                         :id => @outcome.id.to_s,
                         :format => 'json' },
                       { :title => "New Title",
                         :description => "New Description",
                         :vendor_guid => "vendorguid9000",
                         :calculation_method => method,
                         :calculation_int => int[:bad] },
                       {},
                       { :expected_status => 400 })
                @outcome.reload
              }.to_not change{@outcome.calculation_int}

              expect(@outcome.calculation_method).to eql(method)
            end
          end
        end

        it "should set a default calculation_method of 'highest' if the record is being re-saved (previously created)" do
          # The order here is intentional.  We don't want to trigger any callbacks on LearningOutcome
          # because it will take away our nil calculation_method.  The nil is required in order to
          # simulate pre-existing learning outcome records that have nil calculation_methods
          @outcome.update_column(:calculation_method, nil)

          api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                   { :controller => 'outcomes_api',
                     :action => 'update',
                     :id => @outcome.id.to_s,
                     :format => 'json' },
                   { :title => "New Title",
                     :description => "New Description",
                     :vendor_guid => "vendorguid9000",
                     :calculation_method => nil })

          @outcome.reload
          expect(@outcome.calculation_method).to eq('highest')
        end

        it "should return a sensible error message for an incorrect calculation_method" do
          bad_calc_method = 'foo bar baz quz'
          expect(@outcome.calculation_method).not_to eq(bad_calc_method)

          json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                   { :controller => 'outcomes_api',
                     :action => 'update',
                     :id => @outcome.id.to_s,
                     :format => 'json' },
                   { :title => "New Title",
                     :description => "New Description",
                     :vendor_guid => "vendorguid9000",
                     :calculation_method => bad_calc_method,
                     :calculation_int => "3" },
                   {}, # Empty headers dict
                   { :expected_status => 400 })

          @outcome.reload
          expect(json).not_to eq(outcome_json)
          expect(@outcome.calculation_method).not_to eq(bad_calc_method)
          expect(json["errors"]).not_to be_nil
          expect(json["errors"]["calculation_method"]).not_to be_nil
          # make sure there's no errors except on calculation_method
          expect(json["errors"].except("calculation_method")).to be_empty
          expect(json["errors"]["calculation_method"][0]["message"]).to include("calculation_method must be one of")
        end

        context "sensible error message for an incorrect calculation_int" do
          method_to_int = {
            "decaying_average" => 77,
            "n_mastery" => 4,
            "highest" => nil,
            "latest" => nil,
          }
          norm_error_message = "not a valid calculation_int"
          no_calc_int_error_message = "'calculation_int' is not used with calculation_method"
          bad_calc_int = 1500

          method_to_int.each do |method, int|
            it "should return a sensible error message for an incorrect calculation_int when calculation_method is #{method}" do

              @outcome.calculation_method = method
              @outcome.calculation_int = int
              @outcome.save!
              @outcome.reload
              expect(@outcome.calculation_method).to eq(method)
              expect(@outcome.calculation_int).to eq(int)

              json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                       { :controller => 'outcomes_api',
                         :action => 'update',
                         :id => @outcome.id.to_s,
                         :format => 'json' },
                       { :title => "New Title",
                         :description => "New Description",
                         :vendor_guid => "vendorguid9000",
                         # :calculation_method => bad_calc_method,
                         :calculation_int => bad_calc_int },
                       {}, # Empty headers dict
                       { :expected_status => 400 })

              @outcome.reload
              expect(json).not_to eq(outcome_json)
              expect(@outcome.calculation_method).to eq(method)
              expect(@outcome.calculation_int).to eq(int)
              expect(json["errors"]).not_to be_nil
              expect(json["errors"]["calculation_int"]).not_to be_nil
              # make sure there's no errors except on calculation_method
              expect(json["errors"].except("calculation_int")).to be_empty
              if %w[highest latest].include?(method)
                expect(json["errors"]["calculation_int"][0]["message"]).to include(no_calc_int_error_message)
              else
                expect(json["errors"]["calculation_int"][0]["message"]).to include(norm_error_message)
              end
            end
          end
        end
      end
    end
  end

  context "course outcomes" do
    before :once do
      user_with_pseudonym(active_all: true)
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      assignment_model({:course => @course})
      @account = Account.default
      account_admin_user
      @outcome =@course.created_learning_outcomes.create!(
        :title => "My Outcome",
        :description => "Description of my outcome",
        :vendor_guid => "vendorguid9000"
      )
    end

    describe "update" do
      context "mastery calculations" do
        context "not allow updating calculation options after being used for assessing" do
          before :each do
            expect(@outcome).not_to be_assessed

            @outcome.calculation_method = 'decaying_average'
            @outcome.calculation_int = 62
            @outcome.save!
            @outcome.reload

            expect(@outcome.calculation_method).to eq('decaying_average')
            expect(@outcome.calculation_int).to eq(62)

            assess_outcome(@outcome)
            expect(@outcome).to be_assessed

            # make sure that the process of getting assessed didn't change
            # the things our tests expect to be true
            expect(@outcome.calculation_method).to eq('decaying_average')
            expect(@outcome.calculation_int).to eq(62)
          end

          it "should not allow updating calculation method after being used for assessing" do
            expect(@outcome).to be_assessed
            expect(@outcome.calculation_method).to eq('decaying_average')

            json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                     { :controller => 'outcomes_api',
                       :action => 'update',
                       :id => @outcome.id.to_s,
                       :format => 'json' },
                     { :title => "New Title",
                       :description => "New Description",
                       :vendor_guid => "vendorguid9000",
                       :calculation_method => "n_mastery" },
                     {},
                     { :expected_status => 400 })

            @outcome.reload
            expect(json).not_to eq(outcome_json) # it should be filled with an error
            expect(@outcome.calculation_method).to eq('decaying_average')
          end

          it "should not allow updating calculation int after being used for assessing" do
            expect(@outcome).to be_assessed
            expect(@outcome.calculation_method).to eq('decaying_average')
            expect(@outcome.calculation_int).to eq(62)

            json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                     { :controller => 'outcomes_api',
                       :action => 'update',
                       :id => @outcome.id.to_s,
                       :format => 'json' },
                     { :title => "New Title",
                       :description => "New Description",
                       :vendor_guid => "vendorguid9000",
                       :calculation_int => "59" },
                     {},
                     { :expected_status => 400 })

            @outcome.reload
            expect(json).not_to eq(outcome_json) # it should be filled with an error
            expect(@outcome.calculation_method).to eq('decaying_average')
            expect(@outcome.calculation_int).to eq(62)
          end

          it "should return a sensible error message for updating an assessed outcome" do
            expect(@outcome).to be_assessed
            expect(@outcome.calculation_method).to eq('decaying_average')
            expect(@outcome.calculation_int).to eq(62)

            json = api_call(:put, "/api/v1/outcomes/#{@outcome.id}",
                     { :controller => 'outcomes_api',
                       :action => 'update',
                       :id => @outcome.id.to_s,
                       :format => 'json' },
                     { :title => "New Title",
                       :description => "New Description",
                       :vendor_guid => "vendorguid9000",
                       :calculation_method => 'n_mastery',
                       :calculation_int => "5" },
                     {},
                     { :expected_status => 400 })

            @outcome.reload
            expect(json).not_to eq(outcome_json) # it should be filled with an error
            expect(@outcome.calculation_method).to eq('decaying_average')
            expect(@outcome.calculation_int).to eq(62)
            expect(json["errors"]).not_to be_nil
            expect(json["errors"]["calculation_method"]).not_to be_nil
            expect(json["errors"]["calculation_int"]).not_to be_nil
            expect(json["errors"].except("calculation_method", "calculation_int")).to be_empty
            expect(json["errors"]["calculation_method"][0]["message"]).to include("outcome has been used to assess a student")
            expect(json["errors"]["calculation_int"][0]["message"]).to include("outcome has been used to assess a student")
          end
        end
      end
    end
  end
end
