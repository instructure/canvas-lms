require 'spec_helper'

RSpec.describe GradingPeriodSetsController, type: :controller do
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }

  context "given a root account" do
    let(:root_account) { Account.default }
    let(:enrollment_term) { root_account.enrollment_terms.first }
    let(:valid_session) { {} }

    before do
      root_account.allow_feature!(:multiple_grading_periods)
      root_account.enable_feature!(:multiple_grading_periods)
      request.accept = 'application/json'
      @root_user = root_account.users.create! do |user|
        user.accept_terms
        user.register!
      end
      user_session(@root_user)
    end

    describe "GET #index" do
      it "fetches grading period sets" do
        group_helper.create_for_account(root_account)

        get :index, {account_id: root_account.to_param}, valid_session

        expect(json_parse.fetch('grading_period_sets').count).to eql 1
      end

      it "includes grading periods" do
        group = group_helper.create_for_account(root_account)
        period = Factories::GradingPeriodHelper.new.create_for_group(group)
        get :index, {account_id: root_account.to_param}, valid_session
        sets = json_parse.fetch('grading_period_sets')
        periods = sets.first.fetch('grading_periods')
        expect(periods.count).to eql 1
        expect(periods.first.fetch('id').to_s).to eql period.id.to_s
      end
    end

    describe "POST #create" do
      let(:post_create) do
        post :create, {
          account_id: root_account.to_param,
          enrollment_term_ids: [enrollment_term.to_param],
          grading_period_set: group_helper.valid_attributes
        }, valid_session
      end

      context "with valid params" do
        it "creates a new GradingPeriodSet" do
          expect { post_create }.to change(GradingPeriodGroup, :count).by(1)
        end

        it "returns a json representation of a new set" do
          post_create
          set_json = json_parse.fetch('grading_period_set')
          expect(response.status).to eql Rack::Utils.status_code(:created)
          expect(set_json["title"]).to eql group_helper.valid_attributes[:title]
        end
      end

      it "does not require enrollment_term_ids" do
        params = {
          account_id: root_account.to_param,
          grading_period_set: group_helper.valid_attributes
        }
        expect { post :create, params, valid_session }.to change(GradingPeriodGroup, :count).by(1)
      end

      context "given a sub account enrollment term" do
        let(:sub_account) { root_account.sub_accounts.create! }
        let(:sub_account_enrollment_term) do
          sub_account.enrollment_terms.create!
        end

        it "returns a Not Found status code" do
          post :create, {
            account_id: root_account.to_param,
            enrollment_term_ids: [sub_account_enrollment_term.id],
            grading_period_set: group_helper.valid_attributes
          }, valid_session
          expect(response.status).to eql Rack::Utils.status_code(:not_found)
        end
      end
    end

    describe "PATCH #update" do
      let(:new_attributes) { { title: 'An updated title!' } }
      let(:grading_period_set) { group_helper.create_for_account(root_account) }

      context "with valid params" do
        let(:patch_update) do
          patch :update, {
            account_id: root_account.to_param,
            id: grading_period_set.to_param,
            enrollment_term_ids: [enrollment_term.to_param],
            grading_period_set: new_attributes
          }, valid_session
        end

        it "updates the requested grading_period_set" do
          patch_update
          grading_period_set.reload
          expect(grading_period_set.title).to eql new_attributes.fetch(:title)
        end

        it "returns no content" do
          patch_update
          expect(response.status).to eql Rack::Utils.status_code(:no_content)
        end
      end

      it "defaults enrollment_term_ids to empty array" do
        grading_period_set.enrollment_terms << enrollment_term
        patch :update, {
          account_id: root_account.to_param,
          id: grading_period_set.to_param,
          grading_period_set: group_helper.valid_attributes
        }
        expect(response.status).to eql Rack::Utils.status_code(:no_content)
        expect(grading_period_set.reload.enrollment_terms.count).to eql(0)
      end

      context "given a sub account enrollment term" do
        let(:sub_account) { root_account.sub_accounts.create! }
        let(:sub_account_enrollment_term) do
          sub_account.enrollment_terms.create!
        end

        it "returns a Not Found status code" do
          patch :update, {
            id: grading_period_set.to_param,
            account_id: root_account.to_param,
            enrollment_term_ids: [sub_account_enrollment_term.id],
            grading_period_set: group_helper.valid_attributes
          }, valid_session
          expect(response.status).to eql Rack::Utils.status_code(:not_found)
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested grading period set" do
        grading_period_set = group_helper.create_for_account(root_account)
        expect(grading_period_set.reload.workflow_state).to eq 'active'
        delete :destroy, {
          account_id: Account.default,
          id: grading_period_set.to_param
        }, valid_session
        expect(grading_period_set.reload.workflow_state).to eq 'deleted'
      end
    end

    context "given a sub account" do
      let(:sub_account) { root_account.sub_accounts.create! }

      describe "GET #index" do
        it "it fetches sets through the root account" do
          grading_period_set = group_helper.create_for_account(root_account)

          get :index, {account_id: sub_account.to_param}, valid_session

          expect(json_parse.fetch('grading_period_sets').count).to eql 1
        end
      end
    end
  end
end
