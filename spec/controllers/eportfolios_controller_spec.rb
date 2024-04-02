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

require "feedjira"

describe EportfoliosController do
  def eportfolio_category
    @category = @portfolio.eportfolio_categories.create!(name: "some category")
  end

  def category_entry
    @entry = @category.eportfolio_entries.create!(name: "some entry", eportfolio: @portfolio)
  end

  before :once do
    user_factory(active_all: true)
    @user.account_users.create!(account: Account.default, role: student_role)
  end

  describe "GET 'user_index'" do
    before(:once) { eportfolio }

    it "requires authorization" do
      get "user_index"
      expect(response).to be_redirect
    end

    it "redirects if eportfolios are disabled" do
      a = Account.default
      a.settings[:enable_eportfolios] = false
      a.save
      Account.current_domain_root_account = a
      course_with_student_logged_in(active_all: true, user: @user)
      get "user_index"
      expect(response).to be_redirect
    ensure
      Account.current_domain_root_account = nil
    end

    describe "with logged in user" do
      before { user_session(@user) }

      let(:fake_signing_secret) { "asdfasdfasdfasdfasdfasdfasdfasdf" }
      let(:fake_encryption_secret) { "jkl;jkl;jkl;jkl;jkl;jkl;jkl;jkl;" }

      before do
        allow(DynamicSettings).to receive(:find).with(any_args).and_call_original

        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :signing_secret).and_return(fake_signing_secret)
        allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :encryption_secret).and_return(fake_encryption_secret)
      end

      it "assigns variables" do
        get "user_index"
        expect(assigns[:portfolios]).not_to be_nil
        expect(assigns[:portfolios]).not_to be_empty
        expect(assigns[:portfolios][0]).to eql(@portfolio)
      end

      it "exposes the feature state for rich content service to js_env" do
        allow(DynamicSettings).to receive(:find).with("rich-content-service", default_ttl: 5.minutes).and_return(
          DynamicSettings::FallbackProxy.new({ "app-host" => "rce.docker",
                                               "cdn-host" => "rce.docker" })
        )
        get "user_index"
        expect(response).to be_successful
      end
    end
  end

  describe "POST 'create'" do
    it "requires authorization" do
      post "create", params: { eportfolio: { name: "some portfolio" } }
      assert_unauthorized
    end

    it "creates portfolio" do
      user_session(@user)
      post "create", params: { eportfolio: { name: "some portfolio" } }
      expect(response).to be_redirect
      expect(assigns[:portfolio]).not_to be_nil
      expect(assigns[:portfolio].name).to eql("some portfolio")
    end

    it "prevents creation for unverified users if account requires it" do
      Account.default.tap do |a|
        a.settings[:require_confirmed_email] = true
        a.save!
      end

      user_session(@user)
      post "create", params: { eportfolio: { name: "some portfolio" } }

      expect(response).to be_redirect
      expect(response.location).to eq root_url
      expect(flash[:warning]).to include("Complete registration")
    end
  end

  describe "GET 'show'" do
    before(:once) { eportfolio }

    describe "without being logged in" do
      it "complains if the eportfolio is not public" do
        get "show", params: { id: @portfolio.id }
        assert_unauthorized
      end

      it "complains if portfolio is public but eportfolios are disabled" do
        a = Account.default
        a.settings[:enable_eportfolios] = false
        a.save
        Account.current_domain_root_account = a
        @portfolio.public = true
        @portfolio.save!
        get "show", params: { id: @portfolio.id }
        assert_unauthorized
      ensure
        Account.current_domain_root_account = nil
      end

      it "complains if portfolio is not public and eportfolios are disabled" do
        a = Account.default
        a.settings[:enable_eportfolios] = false
        a.save
        Account.current_domain_root_account = a
        course_with_student_logged_in(active_all: true, user: @user)
        get "show", params: { id: @portfolio.id }
        assert_unauthorized
      ensure
        Account.current_domain_root_account = nil
      end
    end

    describe "with an authorized user" do
      before { user_session(@user) }

      it "shows portfolio" do
        get "show", params: { id: @portfolio.id }
        expect(response).to be_successful
        expect(assigns[:portfolio]).not_to be_nil
      end

      it "creates a category if one doesn't exist" do
        get "show", params: { id: @portfolio.id }
        expect(response).to be_successful
        expect(assigns[:category]).not_to be_nil
      end

      it "creates an entry in the first category if one doesn't exist" do
        @portfolio.eportfolio_categories.create!(name: "Home")
        get "show", params: { id: @portfolio.id }
        expect(response).to be_successful
        expect(assigns[:page]).not_to be_nil
      end

      describe "js_env" do
        it "sets SKIP_ENHANCING_USER_CONTENT to true" do
          @portfolio.eportfolio_categories.create!(name: "Home")
          get "show", params: { id: @portfolio.id, view: "preview" }
          expect(assigns.dig(:js_env, :SKIP_ENHANCING_USER_CONTENT)).to be true
        end
      end
    end

    describe "assigns[:owner_url]" do
      before do
        @portfolio.public = true
        @portfolio.save!
      end

      it "does not get set when not logged in" do
        get "show", params: { id: @portfolio.id }
        expect(assigns[:owner_url]).to be_nil
      end

      context "with profiles enabled" do
        before do
          Account.default.update_attribute :settings, enable_profiles: true
        end

        it "is the profile url" do
          user_session(@user)
          get "show", params: { id: @portfolio.id }
          expect(assigns[:owner_url]).to eq user_profile_url(@portfolio.user)
        end

        it "does not get set when portfolio owner is not visible to user" do
          user_session user_factory(active_all: true)
          get "show", params: { id: @portfolio.id }
          expect(assigns[:owner_url]).to be_nil
        end
      end

      context "with profiles disabled" do
        before do
          Account.default.update_attribute :settings, enable_profiles: false
        end

        it "is the settings url for the owner" do
          user_session(@user)
          get "show", params: { id: @portfolio.id }
          expect(assigns[:owner_url]).to eq profile_url
        end

        it "is the user url for an admin" do
          user_with_pseudonym(user: @portfolio.user)
          user_session(account_admin_user)
          get "show", params: { id: @portfolio.id }
          expect(assigns[:owner_url]).to eq user_url(@portfolio.user)
        end

        it "does not get set otherwise" do
          course_with_teacher(active_all: true)
          student_in_course(course: @course, user: @portfolio.user)
          user_session(@teacher)
          get "show", params: { id: @portfolio.id }
          expect(assigns[:owner_url]).to be_nil
        end
      end
    end

    context "spam eportfolios" do
      before(:once) do
        @portfolio.update!(public: true)
      end

      context "when the user is the author of the eportfolio" do
        it "renders the eportfolio when it is spam" do
          @portfolio.update!(spam_status: "marked_as_spam")
          user_session(@user)
          get :show, params: { id: @portfolio.id }

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
          get :show, params: { id: @portfolio.id }

          assert_unauthorized
        end
      end

      context "when the user is an admin" do
        before(:once) do
          @admin = account_admin_user
        end

        it "renders the eportfolio when the eportfolio is spam and the admin has :moderate_user_content permissions" do
          @portfolio.update!(spam_status: "marked_as_spam")
          Account.default.role_overrides.create!(role: admin_role, enabled: true, permission: :moderate_user_content)
          user_session(@admin)
          get :show, params: { id: @portfolio.id }

          expect(response).to have_http_status(:ok)
        end

        it "is unauthorized when the eportfolio is spam and the admin does not have :moderate_user_content permissions" do
          @portfolio.update!(spam_status: "marked_as_spam")
          Account.default.role_overrides.create!(role: admin_role, enabled: false, permission: :moderate_user_content)
          user_session(@admin)
          get :show, params: { id: @portfolio.id }

          assert_unauthorized
        end
      end
    end
  end

  describe "PUT 'update'" do
    before(:once) { eportfolio }

    it "requires authorization" do
      put "update", params: { id: @portfolio.id, eportfolio: { name: "new title" } }
      assert_unauthorized
    end

    it "updates portfolio" do
      user_session(@user)
      put "update", params: { id: @portfolio.id, eportfolio: { name: "new title" } }
      expect(response).to be_redirect
      expect(assigns[:portfolio]).not_to be_nil
      expect(assigns[:portfolio].name).to eql("new title")
    end

    context "spam eportfolios" do
      context "when the user is the author" do
        it "can not make updates to the eportfolio if it has been flagged as possible spam" do
          @portfolio.update!(spam_status: "flagged_as_possible_spam")
          user_session(@user)
          put :update, params: { id: @portfolio.id, eportfolio: { name: "not spam i promise ;)" } }
          expect(response).to have_http_status(:unauthorized)
        end

        it "can not make updates to the eportfolio if it has been marked as spam" do
          @portfolio.update!(spam_status: "marked_as_spam")
          user_session(@user)
          put :update, params: { id: @portfolio.id, eportfolio: { name: "not spam i promise ;)" } }
          expect(response).to have_http_status(:unauthorized)
        end

        it "can make updates to the eportfolio if it has been marked as safe" do
          @portfolio.update!(spam_status: "marked_as_safe")
          user_session(@user)
          put :update, params: { id: @portfolio.id, eportfolio: { name: "new title" } }
          expect(response).to be_redirect
          expect(assigns[:portfolio].name).to eq("new title")
        end

        it "cannot update the spam_status attribute" do
          user_session(@user)
          put :update, params: { id: @portfolio.id, eportfolio: { name: "new title", spam_status: "marked_as_safe" } }
          expect(response).to be_redirect
          expect(assigns[:portfolio].spam_status).to be_nil
        end
      end

      context "when the user is an admin" do
        before(:once) do
          @admin = account_admin_user
        end

        it "can change the spam_status attribute if granted the moderate_user_content permission" do
          @portfolio.update!(spam_status: "marked_as_spam")
          Account.default.role_overrides.create!(role: admin_role, enabled: true, permission: :moderate_user_content)
          user_session(@admin)
          put :update, params: { id: @portfolio.id, eportfolio: { spam_status: "marked_as_safe" } }
          expect(response).to be_redirect
          expect(assigns[:portfolio].spam_status).to eq("marked_as_safe")
        end

        it "cannot change any attrs besides spam_status if granted the moderate_user_content permission" do
          Account.default.role_overrides.create!(role: admin_role, enabled: true, permission: :moderate_user_content)
          user_session(@admin)
          put :update, params: { id: @portfolio.id, eportfolio: { name: "changed name" } }
          expect(response).to be_redirect
          expect(assigns[:portfolio].name).to be_nil
        end

        it "cannot change the spam_status attribute if not granted the moderate_user_content permission" do
          @portfolio.update!(spam_status: "marked_as_spam")
          Account.default.role_overrides.create!(role: admin_role, enabled: false, permission: :moderate_user_content)
          user_session(@admin)
          put :update, params: { id: @portfolio.id, eportfolio: { spam_status: "marked_as_safe" } }
          assert_unauthorized
        end
      end
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { eportfolio }

    it "requires authorization" do
      delete "destroy", params: { id: @portfolio.id }
      assert_unauthorized
    end

    it "deletes portfolio" do
      user_session(@user)
      delete "destroy", params: { id: @portfolio.id }
      expect(assigns[:portfolio]).not_to be_nil
      expect(assigns[:portfolio]).not_to be_frozen
      expect(assigns[:portfolio]).to be_deleted
      @user.reload
      expect(@user.eportfolios).to include(@portfolio)
      expect(@user.eportfolios.active).not_to include(@portfolio)
    end
  end

  describe "POST 'reorder_categories'" do
    before(:once) { eportfolio }

    it "requires authorization" do
      post "reorder_categories", params: { eportfolio_id: @portfolio.id, order: "" }
      assert_unauthorized
    end

    it "reorders categories" do
      user_session(@user)
      c1 = eportfolio_category
      c2 = eportfolio_category
      c3 = eportfolio_category
      expect(c1.position).to be(1)
      expect(c2.position).to be(2)
      expect(c3.position).to be(3)
      post "reorder_categories", params: { eportfolio_id: @portfolio.id, order: "#{c2.id},#{c3.id},#{c1.id}" }
      expect(response).to be_successful
      c1.reload
      c2.reload
      c3.reload
      expect(c1.position).to be(3)
      expect(c2.position).to be(1)
      expect(c3.position).to be(2)
    end
  end

  describe "POST 'reorder_categories' cross shard" do
    specs_require_sharding
    let!(:user) { user_model }

    it "reorders categories" do
      user.associate_with_shard(@shard1)
      @shard1.activate { @portfolio = Eportfolio.create!(user_id: user) }
      user_session(user)
      c1 = eportfolio_category
      c2 = eportfolio_category
      c3 = eportfolio_category
      expect(c1.position).to be(1)
      expect(c2.position).to be(2)
      expect(c3.position).to be(3)
      [c2, c3, c1].map(&:id).join(",")
      post "reorder_categories", params: { eportfolio_id: @portfolio.id, order: "#{c2.id},#{c3.id},#{c1.id}" }
      expect(response).to be_successful
      c1.reload
      c2.reload
      c3.reload
      expect(c1.position).to be(3)
      expect(c2.position).to be(1)
      expect(c3.position).to be(2)
    end
  end

  describe "POST 'reorder_entries'" do
    before(:once) { eportfolio }

    it "requires authorization" do
      post "reorder_entries", params: { eportfolio_id: @portfolio.id, order: "", eportfolio_category_id: 1 }
      assert_unauthorized
    end

    it "reorders entries" do
      user_session(@user)
      eportfolio_category
      e1 = category_entry
      e2 = category_entry
      e3 = category_entry
      expect(e1.position).to be(1)
      expect(e2.position).to be(2)
      expect(e3.position).to be(3)
      post "reorder_entries", params: { eportfolio_id: @portfolio.id, eportfolio_category_id: @category.id, order: "#{e2.id},#{e3.id},#{e1.id}" }
      e1.reload
      e2.reload
      e3.reload
      expect(e1.position).to be(3)
      expect(e2.position).to be(1)
      expect(e3.position).to be(2)
    end
  end

  describe "GET 'public_feed.atom'" do
    before(:once) do
      eportfolio
      @portfolio.public = true
      @portfolio.save!
      eportfolio_category
      category_entry
    end

    it "includes absolute path for rel='self' link" do
      get "public_feed", params: { eportfolio_id: @portfolio.id }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.feed_url).to match(%r{http://})
    end

    it "includes an author for each entry" do
      get "public_feed", params: { eportfolio_id: @portfolio.id }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all? { |e| e.author.present? }).to be_truthy
    end
  end

  describe "GET 'export'" do
    before(:once) do
      eportfolio
      @old_zipfile = @portfolio.attachments.build(display_name: "eportfolio.zip")
      @old_zipfile.workflow_state = "to_be_zipped"
      @old_zipfile.file_state = "0"
      @old_zipfile.user = @user
      @old_zipfile.save!
      Attachment.where(id: @old_zipfile).update_all(created_at: 1.day.ago)
    end

    it "hard deletes old zips if there are no associated attachments" do
      expect(@portfolio.attachments.count).to eq 1
      expect(@old_zipfile.related_attachments.exists?).to be_falsey

      user_session(@user)
      get "export", params: { eportfolio_id: @portfolio.id }

      @portfolio.reload
      expect(@portfolio.attachments.count).to eq 1
      expect(@portfolio.attachments.first.id).not_to eq @old_zipfile.id
    end

    it "hard deletes old zips even if there are associated attachments" do
      expect(@portfolio.attachments.count).to eq 1
      cloned_att = @old_zipfile.clone_for(@user)
      cloned_att.workflow_state = "to_be_zipped"
      cloned_att.file_state = "0"
      cloned_att.save!
      expect(@old_zipfile.reload.related_attachments.exists?).to be_truthy

      user_session(@user)
      get "export", params: { eportfolio_id: @portfolio.id }

      @portfolio.reload
      expect(@portfolio.attachments.count).to eq 1
      expect(@portfolio.attachments.map(&:file_state)).not_to include "deleted"
    end

    it "does not fail on export if there is an empty entry" do
      @portfolio.ensure_defaults
      @portfolio.update_attribute :name, "test"
      ee = EportfolioEntry.create!({ eportfolio: @portfolio, eportfolio_category: @portfolio.eportfolio_categories[0] })
      ee.parse_content({})
      ee.save!

      to_zip = @portfolio.attachments[0]
      ContentZipper.new.zip_eportfolio(to_zip, @portfolio)
      expect(@portfolio.attachments[0].workflow_state).to include "zipped"
    end

    it "deals with long page names" do
      @portfolio.update name: "blah"
      long_category = @portfolio.eportfolio_categories.create! name: "A" * 200
      long_category.eportfolio_entries.create! name: "B" * 200, eportfolio: @portfolio
      to_zip = @portfolio.attachments.first
      ContentZipper.new.zip_eportfolio(to_zip, @portfolio)
      expect(@portfolio.attachments.first.workflow_state).to eq "zipped"
    end
  end
end
