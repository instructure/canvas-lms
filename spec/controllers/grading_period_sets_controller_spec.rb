# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

RSpec.describe GradingPeriodSetsController do
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }

  context "given a root account" do
    let(:root_account) { Account.default }
    let(:enrollment_term) { root_account.enrollment_terms.first }
    let(:valid_session) { {} }

    before do
      request.accept = "application/json"
      @root_user = root_account.users.create! do |user|
        user.accept_terms
        user.register!
      end
      user_session(@root_user)
    end

    describe "GET #index" do
      before :once do
        @groups = (1..10).map do |i|
          group_helper.create_for_account(root_account, title: "Grading Period Set #{i}")
        end
      end

      it "fetches grading period sets" do
        get :index, params: { account_id: root_account.to_param }, session: valid_session
        expect(json_parse.fetch("grading_period_sets").count).to be 10
      end

      it "includes grading periods" do
        group = @groups.first
        period = Factories::GradingPeriodHelper.new.create_for_group(group)
        get :index, params: { account_id: root_account.to_param }, session: valid_session
        set = json_parse.fetch("grading_period_sets").detect { |s| s["id"] == group.id.to_s }
        periods = set.fetch("grading_periods")
        expect(periods.count).to be 1
        expect(periods.first.fetch("id").to_s).to eql period.id.to_s
      end

      it "paginates the grading period sets" do
        get :index, params: { account_id: root_account.to_param }, session: valid_session
        expect(json_parse["meta"]).to have_key("pagination")
      end

      it "orders the grading period sets by id" do
        # the next two lines force an unordered query to be consistently out of
        # natural order, which ensures the assertion can predictably fail
        @groups.take(5).map(&:destroy)
        @groups.take(5).each { |group| group.update!(workflow_state: "active") }
        get :index, params: { account_id: root_account.to_param }, session: valid_session
        set_ids = json_parse.fetch("grading_period_sets").pluck("id")
        expect(set_ids).to eql(@groups.sort_by(&:id).map { |group| group.id.to_s })
      end
    end

    describe "POST #create" do
      let(:post_create) do
        post :create,
             params: {
               account_id: root_account.to_param,
               enrollment_term_ids: [enrollment_term.to_param],
               grading_period_set: group_helper.valid_attributes(weighted: true)
             },
             session: valid_session
      end

      context "with valid params" do
        it "creates a new GradingPeriodSet" do
          expect { post_create }.to change(GradingPeriodGroup, :count).by(1)
        end

        it "returns a json representation of a new set" do
          post_create
          set_json = json_parse.fetch("grading_period_set")
          expect(response.status).to eql Rack::Utils.status_code(:created)
          expect(set_json["title"]).to eql group_helper.valid_attributes[:title]
          expect(set_json["weighted"]).to be true
        end
      end

      it "does not require enrollment_term_ids" do
        params = {
          account_id: root_account.to_param,
          grading_period_set: group_helper.valid_attributes
        }
        expect { post :create, params:, session: valid_session }.to change(GradingPeriodGroup, :count).by(1)
      end

      context "given a sub account enrollment term" do
        let(:sub_account) { root_account.sub_accounts.create! }
        let(:sub_account_enrollment_term) do
          sub_account.enrollment_terms.create!
        end

        it "returns a Not Found status code" do
          post :create,
               params: {
                 account_id: root_account.to_param,
                 enrollment_term_ids: [sub_account_enrollment_term.id],
                 grading_period_set: group_helper.valid_attributes
               },
               session: valid_session
          expect(response.status).to eql Rack::Utils.status_code(:not_found)
        end
      end
    end

    describe "PATCH #update" do
      let(:new_attributes) { { title: "An updated title!", weighted: false } }
      let(:grading_period_set) { group_helper.create_for_account(root_account) }

      context "with valid params" do
        let(:patch_update) do
          patch :update,
                params: {
                  account_id: root_account.to_param,
                  id: grading_period_set.to_param,
                  enrollment_term_ids: [enrollment_term.to_param],
                  grading_period_set: new_attributes
                },
                session: valid_session
        end

        it "updates the requested grading_period_set" do
          patch_update
          grading_period_set.reload
          expect(grading_period_set.title).to eql new_attributes.fetch(:title)
          expect(grading_period_set.weighted).to eql new_attributes.fetch(:weighted)
        end

        it "returns no content" do
          patch_update
          expect(response.status).to eql Rack::Utils.status_code(:no_content)
        end

        it "recomputes grades when an enrollment term is removed from the set" do
          term = root_account.enrollment_terms.create!
          course = root_account.courses.create!(enrollment_term: term)
          grading_period_set.enrollment_terms << term
          expect(GradeCalculator).to receive(:recompute_final_score) do |_, course_id, _|
            course_id == course.id
          end
          patch :update,
                params: {
                  account_id: root_account.to_param,
                  id: grading_period_set.to_param,
                  enrollment_term_ids: [],
                  grading_period_set: new_attributes
                },
                session: valid_session
        end
      end

      it "defaults enrollment_term_ids to empty array" do
        grading_period_set.enrollment_terms << enrollment_term
        patch :update, params: {
          account_id: root_account.to_param,
          id: grading_period_set.to_param,
          grading_period_set: group_helper.valid_attributes
        }
        expect(response.status).to eql Rack::Utils.status_code(:no_content)
        expect(grading_period_set.reload.enrollment_terms.count).to be(0)
      end

      context "given a sub account enrollment term" do
        let(:sub_account) { root_account.sub_accounts.create! }
        let(:sub_account_enrollment_term) do
          sub_account.enrollment_terms.create!
        end

        it "returns a Not Found status code" do
          patch :update,
                params: {
                  id: grading_period_set.to_param,
                  account_id: root_account.to_param,
                  enrollment_term_ids: [sub_account_enrollment_term.id],
                  grading_period_set: group_helper.valid_attributes
                },
                session: valid_session
          expect(response.status).to eql Rack::Utils.status_code(:not_found)
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested grading period set" do
        grading_period_set = group_helper.create_for_account(root_account)
        expect(grading_period_set.reload.workflow_state).to eq "active"
        delete :destroy,
               params: {
                 account_id: Account.default,
                 id: grading_period_set.to_param
               },
               session: valid_session
        expect(grading_period_set.reload.workflow_state).to eq "deleted"
      end
    end

    context "given a sub account" do
      let(:sub_account) { root_account.sub_accounts.create! }

      describe "GET #index" do
        it "fetches sets through the root account" do
          group_helper.create_for_account(root_account)

          get :index, params: { account_id: sub_account.to_param }, session: valid_session

          expect(json_parse.fetch("grading_period_sets").count).to be 1
        end
      end
    end
  end
end
