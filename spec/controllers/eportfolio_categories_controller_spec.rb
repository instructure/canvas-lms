# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe EportfolioCategoriesController do
  before :once do
    eportfolio_with_user(active_all: true)
    @user.account_users.create!(account: Account.default, role: student_role)
  end

  def eportfolio_category
    @category = @portfolio.eportfolio_categories.create(name: "some name")
  end

  describe "GET 'index'" do
    it "redirects" do
      get "index", params: { eportfolio_id: @portfolio.id }
      expect(response).to be_redirect
    end
  end

  describe "GET 'show'" do
    before(:once) { eportfolio_category }

    it "requires authorization" do
      get "show", params: { eportfolio_id: @portfolio.id, id: 1 }
      assert_unauthorized
    end

    it "assigns variables" do
      user_session(@user)
      get "show", params: { eportfolio_id: @portfolio.id, id: @category.id }
      expect(response).to be_successful
      expect(assigns[:portfolio]).not_to be_nil
      expect(assigns[:portfolio]).to eql(@portfolio)
      expect(assigns[:category]).not_to be_nil
      expect(assigns[:category]).to eql(@category)
    end

    it "responds to named category request" do
      user_session(@user)
      get "show", params: { eportfolio_id: @portfolio.id, category_name: @category.slug }
      expect(response).to be_successful
      expect(assigns[:portfolio]).not_to be_nil
      expect(assigns[:portfolio]).to eql(@portfolio)
      expect(assigns[:category]).not_to be_nil
      expect(assigns[:category]).to eql(@category)
    end

    context "with active submissions by owner" do
      before(:once) do
        course = course_model
        att = attachment_model(filename: "submission.doc", context: @portfolio.user)
        @assignment = course.assignments.create!(title: "some assignment", submission_types: "online_upload")
        @submission = @assignment.submit_homework(@portfolio.user, submission_type: "online_upload", attachments: [att])
      end

      before { user_session(@portfolio.user) }

      it "renders the category without error" do
        get "show", params: { eportfolio_id: @portfolio.id, category_name: @category.slug }
        expect(response).to be_successful
        expect(assigns[:recent_submissions]).not_to be_nil
      end

      it "does not show submissions for unpublished assignments" do
        @assignment.unpublish
        get "show", params: { eportfolio_id: @portfolio.id, category_name: @category.slug }
        expect(response).to be_successful
        expect(assigns[:recent_submissions]).to be_empty
      end

      it "does not show submissions for unpublished courses" do
        @course.update!(workflow_state: "claimed")
        get "show", params: { eportfolio_id: @portfolio.id, category_name: @category.slug }
        expect(response).to be_successful
        expect(assigns[:recent_submissions]).to be_empty
      end
    end

    describe "js_env" do
      it "sets SKIP_ENHANCING_USER_CONTENT to true" do
        user_session(@user)
        get "show", params: { eportfolio_id: @portfolio.id, category_name: @category.slug }
        expect(assigns.dig(:js_env, :SKIP_ENHANCING_USER_CONTENT)).to be true
      end
    end

    context "spam eportfolios" do
      before(:once) do
        @portfolio.update!(public: true)
        @portfolio.eportfolio_entries.create!(eportfolio_category: @category, name: "new page")
      end

      context "when the user is the author of the eportfolio" do
        it "renders the category when the eportfolio is spam" do
          @portfolio.update!(spam_status: "marked_as_spam")
          user_session(@user)
          get :show, params: { eportfolio_id: @portfolio.id, category_name: @category.slug }

          expect(response).to have_http_status(:ok)
        end
      end

      context "when the user is a non-admin, non-author of the eportfolio" do
        before(:once) do
          @other_user = user_model
          @other_user.account_users.create!(account: Account.default, role: student_role)
        end

        it "is unauthorized when the eportfolio is spam" do
          @portfolio.update!(spam_status: "marked_as_spam")
          user_session(@other_user)
          get :show, params: { eportfolio_id: @portfolio.id, category_name: @category.slug }

          assert_unauthorized
        end
      end

      context "when the user is an admin" do
        before(:once) do
          @admin = account_admin_user
        end

        it "renders the category when the eportfolio is spam and the admin has :moderate_user_content permissions" do
          @portfolio.update!(spam_status: "marked_as_spam")
          Account.default.role_overrides.create!(role: admin_role, enabled: true, permission: :moderate_user_content)
          user_session(@admin)
          get :show, params: { eportfolio_id: @portfolio.id, category_name: @category.slug }

          expect(response).to have_http_status(:ok)
        end

        it "is unauthorized when the eportfolio is spam and the admin does not have :moderate_user_content permissions" do
          @portfolio.update!(spam_status: "marked_as_spam")
          Account.default.role_overrides.create!(role: admin_role, enabled: false, permission: :moderate_user_content)
          user_session(@admin)
          get :show, params: { eportfolio_id: @portfolio.id, category_name: @category.slug }

          assert_unauthorized
        end
      end
    end
  end

  describe "POST 'create'" do
    it "requires authorization" do
      post "create", params: { eportfolio_id: @portfolio.id, eportfolio_category: { name: "some portfolio" } }
      assert_unauthorized
    end

    it "creates eportfolio category" do
      user_session(@user)
      post "create", params: { eportfolio_id: @portfolio.id, eportfolio_category: { name: "some category" } }
      expect(response).to be_redirect
      expect(assigns[:category]).not_to be_nil
      expect(assigns[:category].name).to eql("some category")
    end
  end

  describe "PUT 'update'" do
    before(:once) { eportfolio_category }

    it "requires authorization" do
      put "update", params: { eportfolio_id: @portfolio.id, id: @category.id, eportfolio_category: { name: "new name" } }
      assert_unauthorized
    end

    it "updates eportfolio category" do
      user_session(@user)
      put "update", params: { eportfolio_id: @portfolio.id, id: @category.id, eportfolio_category: { name: "new name" } }
      expect(assigns[:category]).not_to be_nil
      expect(assigns[:category]).to eql(@category)
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { eportfolio_category }

    it "requires authorization" do
      delete "destroy", params: { eportfolio_id: @portfolio.id, id: @category.id }
      assert_unauthorized
    end

    it "deletes eportfolio category" do
      user_session(@user)
      delete "destroy", params: { eportfolio_id: @portfolio.id, id: @category.id }
      expect(assigns[:category]).to be_frozen
    end
  end
end
