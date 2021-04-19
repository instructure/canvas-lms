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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EportfolioCategoriesController do
  before :once do
    eportfolio_with_user(:active_all => true)
    @user.account_users.create!(account: Account.default, role: student_role)
  end

  def eportfolio_category
    @category = @portfolio.eportfolio_categories.create(:name => "some name")
  end

  describe "GET 'index'" do
    it "should redirect" do
      get 'index', params: {:eportfolio_id => @portfolio.id}
      expect(response).to be_redirect
    end
  end

  describe "GET 'show'" do
    before(:once) { eportfolio_category }
    it "should require authorization" do
      get 'show', params: {:eportfolio_id => @portfolio.id, :id => 1}
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@user)
      get 'show', params: {:eportfolio_id => @portfolio.id, :id => @category.id}
      expect(response).to be_successful
      expect(assigns[:portfolio]).not_to be_nil
      expect(assigns[:portfolio]).to eql(@portfolio)
      expect(assigns[:category]).not_to be_nil
      expect(assigns[:category]).to eql(@category)
    end

    it "should responsd to named category request" do
      user_session(@user)
      get 'show', params: {:eportfolio_id => @portfolio.id, :category_name => @category.slug}
      expect(response).to be_successful
      expect(assigns[:portfolio]).not_to be_nil
      expect(assigns[:portfolio]).to eql(@portfolio)
      expect(assigns[:category]).not_to be_nil
      expect(assigns[:category]).to eql(@category)
    end

    describe "js_env" do
      it "sets SKIP_ENHANCING_USER_CONTENT to true" do
        user_session(@user)
        get 'show', params: {eportfolio_id: @portfolio.id, category_name: @category.slug}
        expect(assigns.dig(:js_env, :SKIP_ENHANCING_USER_CONTENT)).to be true
      end
    end

    context "spam eportfolios" do
      before(:once) do
        @portfolio.update!(public: true)
        @portfolio.eportfolio_entries.create!(eportfolio_category: @category, name: 'new page')
      end

      context "when the user is the author of the eportfolio" do
        it "renders the category when the eportfolio is spam" do
          @portfolio.update!(spam_status: 'marked_as_spam')
          user_session(@user)
          get :show, params: { eportfolio_id: @portfolio.id, category_name: @category.slug }

          expect(response.status).to eq(200)
        end
      end

      context "when the user is a non-admin, non-author of the eportfolio" do
        before(:once) do
          @other_user = user_model
          @other_user.account_users.create!(account: Account.default, role: student_role)
        end

        it "is unauthorized when the eportfolio is spam" do
          @portfolio.update!(spam_status: 'marked_as_spam')
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
          @portfolio.update!(spam_status: 'marked_as_spam')
          Account.default.role_overrides.create!(role: admin_role, enabled: true, permission: :moderate_user_content)
          user_session(@admin)
          get :show, params: { eportfolio_id: @portfolio.id, category_name: @category.slug }

          expect(response.status).to eq(200)
        end

        it "is unauthorized when the eportfolio is spam and the admin does not have :moderate_user_content permissions" do
          @portfolio.update!(spam_status: 'marked_as_spam')
          Account.default.role_overrides.create!(role: admin_role, enabled: false, permission: :moderate_user_content)
          user_session(@admin)
          get :show, params: { eportfolio_id: @portfolio.id, category_name: @category.slug }

          assert_unauthorized
        end
      end
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', params: {:eportfolio_id => @portfolio.id, :eportfolio_category => {:name => "some portfolio"}}
      assert_unauthorized
    end

    it "should create eportfolio category" do
      user_session(@user)
      post 'create', params: {:eportfolio_id => @portfolio.id, :eportfolio_category => {:name => "some category"}}
      expect(response).to be_redirect
      expect(assigns[:category]).not_to be_nil
      expect(assigns[:category].name).to eql("some category")
    end
  end

  describe "PUT 'update'" do
    before(:once) { eportfolio_category }
    it "should require authorization" do
      put 'update', params: {:eportfolio_id => @portfolio.id, :id => @category.id, :eportfolio_category => {:name => "new name" }}
      assert_unauthorized
    end

    it "should update eportfolio category" do
      user_session(@user)
      put 'update', params: {:eportfolio_id => @portfolio.id, :id => @category.id, :eportfolio_category => {:name => "new name" }}
      expect(assigns[:category]).not_to be_nil
      expect(assigns[:category]).to eql(@category)
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { eportfolio_category }
    it "should require authorization" do
      delete 'destroy', params: {:eportfolio_id => @portfolio.id, :id => @category.id}
      assert_unauthorized
    end

    it "should delete eportfolio category" do
      user_session(@user)
      delete 'destroy', params: {:eportfolio_id => @portfolio.id, :id => @category.id}
      expect(assigns[:category]).to be_frozen
    end
  end
end
