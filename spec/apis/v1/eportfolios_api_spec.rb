# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "apis/api_spec_helper"

describe "EportfoliosApi", type: :request do
  before :once do
    @admin = account_admin_user(active_all: true)
    @other_user = user_with_pseudonym(active_all: true)
    @eportfolio_user = user_with_pseudonym(active_all: true)
    @user = nil # avoid accidents, set explicitly below

    @active_eportfolio = eportfolio_model(user: @eportfolio_user, name: "Fruitcake")
    @flagged_eportfolio = eportfolio_model(user: @eportfolio_user, spam_status: "flagged_as_possible_spam")
    @safe_eportfolio = eportfolio_model(user: @eportfolio_user, spam_status: "marked_as_safe")
    @spam_eportfolio = eportfolio_model(user: @eportfolio_user, spam_status: "marked_as_spam")
    @deleted_eportfolio = eportfolio_model(user: @eportfolio_user, name: "Deletasaur", workflow_state: "deleted")
    @eportfolio = nil # avoid accidents

    EportfolioEntry.create!(name: "Nuts",
                            eportfolio: @active_eportfolio,
                            eportfolio_category: @active_eportfolio.eportfolio_categories.first)
    EportfolioEntry.create!(name: "NestEgg",
                            eportfolio: @deleted_eportfolio,
                            eportfolio_category: @deleted_eportfolio.eportfolio_categories.first)
  end

  describe "#index" do
    it "lists eportfolios" do
      @user = @eportfolio_user
      json = api_call(:get,
                      "/api/v1/users/#{@eportfolio_user.id}/eportfolios",
                      controller: "eportfolios_api",
                      action: "index",
                      format: "json",
                      user_id: @eportfolio_user.id)

      expected = [@active_eportfolio.id, @flagged_eportfolio.id, @safe_eportfolio.id, @spam_eportfolio.id]
      expect(json.pluck("id").sort).to eql expected.sort
    end

    context "as an admin" do
      it "allows listing deleted eportfolios" do
        @user = @admin
        json = api_call(:get,
                        "/api/v1/users/#{@eportfolio_user.id}/eportfolios?include[]=deleted",
                        controller: "eportfolios_api",
                        action: "index",
                        format: "json",
                        user_id: @eportfolio_user.id,
                        include: ["deleted"])

        expect(json.pluck("id").size).to eq 5
        expect(json.select { |j| j["id"] == @deleted_eportfolio.id }).to be_present
      end
    end

    context "as self" do
      it "ignores listing deleted eportfolios" do
        @user = @eportfolio_user
        json = api_call(:get,
                        "/api/v1/users/self/eportfolios?include[]=deleted",
                        controller: "eportfolios_api",
                        action: "index",
                        format: "json",
                        user_id: "self",
                        include: ["deleted"])

        expect(json.size).to eq 4
        expect(json.select { |j| j["id"] == @deleted_eportfolio.id }).to be_empty
      end
    end

    context "as a random other user" do
      it "is unauthorized" do
        @user = @other_user
        api_call(:get,
                 "/api/v1/users/#{@eportfolio_user.id}/eportfolios",
                 {
                   controller: "eportfolios_api",
                   action: "index",
                   format: "json",
                   user_id: @eportfolio_user.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "#show" do
    context "as an admin" do
      it "shows eportfolio details" do
        @user = @admin
        json = api_call(:get,
                        "/api/v1/eportfolios/#{@active_eportfolio.id}",
                        controller: "eportfolios_api",
                        action: "show",
                        format: "json",
                        id: @active_eportfolio.id)

        expect(json["id"]).to eq @active_eportfolio.id
        expect(json["user_id"]).to eq @eportfolio_user.id
        expect(json["name"]).to eq "Fruitcake"
        expect(json["public"]).to be false
        expect(json["created_at"]).to eq @active_eportfolio.created_at.iso8601
        expect(json["updated_at"]).to eq @active_eportfolio.updated_at.iso8601
        expect(json["workflow_state"]).to eq "active"
        expect(json["deleted_at"]).to be_nil
        expect(json["spam_status"]).to be_nil
      end

      it "is unauthorized for a deleted eportfolio" do
        @user = @admin
        api_call(:get,
                 "/api/v1/eportfolios/#{@deleted_eportfolio.id}",
                 {
                   controller: "eportfolios_api",
                   action: "show",
                   format: "json",
                   id: @deleted_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "as self" do
      it "shows eportfolio details" do
        @user = @eportfolio_user
        json = api_call(:get,
                        "/api/v1/eportfolios/#{@active_eportfolio.id}",
                        controller: "eportfolios_api",
                        action: "show",
                        format: "json",
                        id: @active_eportfolio.id)

        expect(json["id"]).to eq @active_eportfolio.id
        expect(json["user_id"]).to eq @eportfolio_user.id
        expect(json["name"]).to eq "Fruitcake"
        expect(json["public"]).to be false
        expect(json["created_at"]).to eq @active_eportfolio.created_at.iso8601
        expect(json["updated_at"]).to eq @active_eportfolio.updated_at.iso8601
        expect(json["workflow_state"]).to eq "active"
        expect(json["deleted_at"]).to be_nil
        expect(json["spam_status"]).to be_nil
      end

      it "is unauthorized for a deleted eportfolio" do
        @user = @other_user
        api_call(:get,
                 "/api/v1/eportfolios/#{@deleted_eportfolio.id}",
                 {
                   controller: "eportfolios_api",
                   action: "show",
                   format: "json",
                   id: @deleted_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "as a random other user" do
      it "is unauthorized" do
        @user = @other_user
        api_call(:get,
                 "/api/v1/eportfolios/#{@active_eportfolio.id}",
                 {
                   controller: "eportfolios_api",
                   action: "show",
                   format: "json",
                   id: @active_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "#delete" do
    context "as an admin" do
      it "deletes an eportfolio" do
        @user = @admin
        json = api_call(:delete,
                        "/api/v1/eportfolios/#{@active_eportfolio.id}",
                        controller: "eportfolios_api",
                        action: "delete",
                        format: "json",
                        id: @active_eportfolio.id)

        expect(json["id"]).to eq @active_eportfolio.id
        expect(@active_eportfolio.reload).to be_deleted
      end
    end

    context "as self" do
      it "deletes an eportfolio" do
        @user = @eportfolio_user
        json = api_call(:delete,
                        "/api/v1/eportfolios/#{@active_eportfolio.id}",
                        controller: "eportfolios_api",
                        action: "delete",
                        format: "json",
                        id: @active_eportfolio.id)

        expect(json["id"]).to eq @active_eportfolio.id
        expect(@active_eportfolio.reload).to be_deleted
      end
    end

    context "as a random other user" do
      it "is unauthorized" do
        @user = @other_user
        api_call(:delete,
                 "/api/v1/eportfolios/#{@active_eportfolio.id}",
                 {
                   controller: "eportfolios_api",
                   action: "delete",
                   format: "json",
                   id: @active_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "#pages" do
    context "as an admin" do
      it "returns eportfolio pages" do
        @user = @admin
        json = api_call(:get,
                        "/api/v1/eportfolios/#{@active_eportfolio.id}/pages",
                        controller: "eportfolios_api",
                        action: "pages",
                        format: "json",
                        eportfolio_id: @active_eportfolio.id)

        expect(json.pluck("id").size).to eq 2
      end

      it "is unauthorized for a deleted eportfolio" do
        @user = @admin
        api_call(:get,
                 "/api/v1/eportfolios/#{@deleted_eportfolio.id}/pages",
                 {
                   controller: "eportfolios_api",
                   action: "pages",
                   format: "json",
                   eportfolio_id: @deleted_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "as self" do
      it "returns eportfolio_pages" do
        @user = @eportfolio_user
        json = api_call(:get,
                        "/api/v1/eportfolios/#{@active_eportfolio.id}/pages",
                        controller: "eportfolios_api",
                        action: "pages",
                        format: "json",
                        eportfolio_id: @active_eportfolio.id)

        expect(json.pluck("id").size).to eq 2
      end

      it "is unauthorized for a deleted eportfolio" do
        @user = @eportfolio_user
        api_call(:get,
                 "/api/v1/eportfolios/#{@deleted_eportfolio.id}/pages",
                 {
                   controller: "eportfolios_api",
                   action: "pages",
                   format: "json",
                   eportfolio_id: @deleted_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "as a random other user" do
      it "is unauthorized" do
        @user = @other_user
        api_call(:get,
                 "/api/v1/eportfolios/#{@active_eportfolio.id}/pages",
                 {
                   controller: "eportfolios_api",
                   action: "pages",
                   format: "json",
                   eportfolio_id: @active_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "#moderate" do
    context "as an admin" do
      it "updates the spam status for the eportfolio" do
        @user = @admin
        api_call(:put,
                 "/api/v1/eportfolios/#{@active_eportfolio.id}/moderate?spam_status=marked_as_spam",
                 controller: "eportfolios_api",
                 action: "moderate",
                 format: "json",
                 eportfolio_id: @active_eportfolio.id,
                 spam_status: "marked_as_spam")

        expect(@active_eportfolio.reload.spam_status).to eq "marked_as_spam"
      end

      it "is not allowed for a deleted eportfolio" do
        @user = @admin
        api_call(:put,
                 "/api/v1/eportfolios/#{@deleted_eportfolio.id}/moderate?spam_status=marked_as_spam",
                 {
                   controller: "eportfolios_api",
                   action: "moderate",
                   format: "json",
                   eportfolio_id: @deleted_eportfolio.id,
                   spam_status: "marked_as_spam"
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "is not allowed for an invalid spam_status" do
        @user = @admin
        api_call(:put,
                 "/api/v1/eportfolios/#{@active_eportfolio.id}/moderate?spam_status=spam_it_up",
                 {
                   controller: "eportfolios_api",
                   action: "moderate",
                   format: "json",
                   eportfolio_id: @active_eportfolio.id,
                   spam_status: "spam_it_up"
                 },
                 {},
                 {},
                 { expected_status: 400 })
      end
    end

    context "as self" do
      it "is unauthorized" do
        @user = @eportfolio_user
        api_call(:put,
                 "/api/v1/eportfolios/#{@active_eportfolio.id}/moderate?spam_status=marked_as_spam",
                 {
                   controller: "eportfolios_api",
                   action: "moderate",
                   format: "json",
                   eportfolio_id: @active_eportfolio.id,
                   spam_status: "marked_as_spam"
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "as a random other user" do
      it "is unauthorized" do
        @user = @other_user
        api_call(:put,
                 "/api/v1/eportfolios/#{@active_eportfolio.id}/moderate?spam_status=marked_as_spam",
                 {
                   controller: "eportfolios_api",
                   action: "moderate",
                   format: "json",
                   eportfolio_id: @active_eportfolio.id,
                   spam_status: "marked_as_spam"
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "#moderate_all" do
    context "as an admin" do
      it "updates the spam status for all active eportfolios" do
        @user = @admin
        api_call(:put,
                 "/api/v1/users/#{@eportfolio_user.id}/eportfolios?spam_status=marked_as_spam",
                 controller: "eportfolios_api",
                 action: "moderate_all",
                 format: "json",
                 user_id: @eportfolio_user.id,
                 spam_status: "marked_as_spam")

        expect(@active_eportfolio.reload.spam_status).to eq "marked_as_spam"
        expect(@flagged_eportfolio.reload.spam_status).to eq "marked_as_spam"
        expect(@safe_eportfolio.reload.spam_status).to eq "marked_as_spam"
        expect(@spam_eportfolio.reload.spam_status).to eq "marked_as_spam"
        expect(@deleted_eportfolio.reload.spam_status).to be_nil
      end

      it "is not allowed for an invalid spam_status" do
        @user = @admin
        api_call(:put,
                 "/api/v1/users/#{@eportfolio_user.id}/eportfolios?spam_status=spamorific",
                 {
                   controller: "eportfolios_api",
                   action: "moderate_all",
                   format: "json",
                   user_id: @eportfolio_user.id,
                   spam_status: "spamorific"
                 },
                 {},
                 {},
                 { expected_status: 400 })
      end
    end

    context "as self" do
      it "is unauthorized" do
        @user = @eportfolio_user
        api_call(:put,
                 "/api/v1/users/#{@eportfolio_user.id}/eportfolios?spam_status=marked_as_spam",
                 {
                   controller: "eportfolios_api",
                   action: "moderate_all",
                   format: "json",
                   user_id: @eportfolio_user.id,
                   spam_status: "marked_as_spam"
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "as a random other user" do
      it "is unauthorized" do
        @user = @other_user
        api_call(:put,
                 "/api/v1/users/#{@eportfolio_user.id}/eportfolios?spam_status=marked_as_spam",
                 {
                   controller: "eportfolios_api",
                   action: "moderate_all",
                   format: "json",
                   user_id: @eportfolio_user.id,
                   spam_status: "marked_as_spam"
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end
  end

  describe "#restore" do
    context "as an admin" do
      it "restores the eportfolio" do
        @user = @admin
        json = api_call(:put,
                        "/api/v1/eportfolios/#{@deleted_eportfolio.id}/restore",
                        controller: "eportfolios_api",
                        action: "restore",
                        format: "json",
                        eportfolio_id: @deleted_eportfolio.id)

        expect(json["id"]).to eq @deleted_eportfolio.id
        expect(@deleted_eportfolio.reload).to be_active
      end
    end

    context "as self" do
      it "is unauthorized" do
        @user = @eportfolio_user
        api_call(:put,
                 "/api/v1/eportfolios/#{@deleted_eportfolio.id}/restore",
                 {
                   controller: "eportfolios_api",
                   action: "restore",
                   format: "json",
                   eportfolio_id: @deleted_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "as a random other user" do
      it "is unauthorized" do
        @user = @other_user
        api_call(:put,
                 "/api/v1/eportfolios/#{@deleted_eportfolio.id}/restore",
                 {
                   controller: "eportfolios_api",
                   action: "restore",
                   format: "json",
                   eportfolio_id: @deleted_eportfolio.id
                 },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end
  end
end
