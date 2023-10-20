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
#

require "webmock/rspec"

describe ReleaseNotesController do
  around do |example|
    override_dynamic_settings(private: { canvas: { "release_notes.yml": {
      ddb_endpoint: ENV.fetch("DDB_ENDPOINT", "http://dynamodb:8000/"),
      ddb_table_name: "canvas_test_release_notes#{ENV.fetch("PARALLEL_INDEX", "")}"
    }.to_json } }) do
      ReleaseNotes::DevUtils.initialize_ddb_for_development!(recreate: true)
      example.run
    end
  end

  let(:show_at) { Time.now.utc.change(usec: 0) - 1.hour }

  let(:note) do
    note = ReleaseNote.new
    note.target_roles = ["student", "ta"]
    note.set_show_at("test", show_at)
    note.published = false
    note["en"] = {
      title: "A boring title",
      description: "A boring description",
      url: "https://example.com/note0"
    }
    note["es"] = {
      title: "A boring title en español",
      description: "A boring description en español",
      url: "https://es.example.com/note0"
    }
    note.save
    note
  end

  before do
    user_session(account_admin_user(account: Account.site_admin))
  end

  describe "index" do
    it "returns the object without langs by default" do
      the_note = note
      get "index"
      res = response.parsed_body
      expect(res.first["id"]).to eq(the_note.id)
      expect(res.first["langs"]).to be_nil
    end

    it "returns the object with langs with includes[]=langs" do
      the_note = note
      get "index", params: { includes: ["langs"] }
      res = response.parsed_body
      expect(res.first["id"]).to eq(the_note.id)
      expect(res.first.dig("langs", "en")&.with_indifferent_access).to eq(note["en"].with_indifferent_access)
    end
  end

  describe "create" do
    it "creates a note with the expected values" do
      post "create",
           params: {
             target_roles: ["user"],
             show_ats: { "test" => show_at },
             published: true,
             langs: {
               en: {
                 title: "A great title",
                 description: "A great description",
                 url: "https://example.com/note1"
               }
             }
           },
           as: :json
      res = response.parsed_body
      the_note = ReleaseNote.find(res["id"])
      expect(the_note.target_roles).to eq(["user"])
      expect(the_note.show_ats["test"]).to eq(show_at)
      expect(the_note.published).to be(true)
      expect(the_note["en"][:title]).to eq("A great title")
      expect(the_note["en"][:description]).to eq("A great description")
      expect(the_note["en"][:url]).to eq("https://example.com/note1")
    end
  end

  describe "update" do
    it "updates an existing note in the expected way" do
      the_note = ReleaseNote.find(note.id)
      expect(the_note.target_roles).to_not be_nil
      put "update",
          params: {
            id: the_note.id,
            target_roles: ["user"],
            show_ats: { "test" => show_at + 35.minutes },
            published: true,
            langs: {
              en: {
                title: "A great title",
                description: "A great description",
                url: "https://example.com/note1"
              }
            }
          },
          as: :json
      the_note = ReleaseNote.find(note.id)
      expect(the_note.target_roles).to eq(["user"])
      expect(the_note.show_ats["test"]).to eq(show_at + 35.minutes)
      expect(the_note.published).to be(true)
      expect(the_note["en"][:title]).to eq("A great title")
      expect(the_note["en"][:description]).to eq("A great description")
      expect(the_note["en"][:url]).to eq("https://example.com/note1")
    end

    it "works when not updating anything" do
      the_note = ReleaseNote.find(note.id)
      expect(the_note.target_roles).to_not be_nil
      put "update", params: { id: the_note.id }
      expect(response).to have_http_status(:ok)
      res = response.parsed_body
      expect(res["id"]).to eq(the_note.id)
    end

    it "returns 404 for non-existant notes" do
      put "update", params: { id: SecureRandom.uuid, target_roles: ["user"] }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "destroy" do
    it "removes an existing note" do
      the_note = ReleaseNote.find(note.id)
      expect(the_note).to_not be_nil
      delete "destroy", params: { id: the_note.id }
      expect { ReleaseNote.find(note.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns 404 for non-existant notes" do
      delete "destroy", params: { id: SecureRandom.uuid }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "publish" do
    it "publishes an unpublished note" do
      the_note = ReleaseNote.find(note.id)
      expect(the_note.published).to be(false)
      put "publish", params: { id: the_note.id }
      the_note = ReleaseNote.find(note.id)
      expect(the_note.published).to be(true)
    end
  end

  describe "unpublish" do
    it "publishes an unpublished note" do
      the_note = ReleaseNote.find(note.id)
      the_note.published = true
      the_note.save

      expect(the_note.published).to be(true)
      delete "unpublish", params: { id: the_note.id }
      the_note = ReleaseNote.find(note.id)
      expect(the_note.published).to be(false)
    end
  end

  describe "latest" do
    before do
      @student_enrollment = student_in_course(active_all: true)
      user_session(@student_enrollment.user)

      the_note = ReleaseNote.find(note.id)
      the_note.published = true
      the_note.save
    end

    it "returns english notes by default" do
      I18n.with_locale(:ar) do
        get "latest"
        expect(response).to have_http_status(:ok)
        res = response.parsed_body
        expect(res.length).to eq(1)

        json_note = res[0]
        expect(json_note["id"]).to eq(note.id)
        expect(json_note["title"]).to eq(note["en"][:title])
        expect(json_note["description"]).to eq(note["en"][:description])
        expect(json_note["url"]).to eq(note["en"][:url])
        expect(Time.zone.parse(json_note["date"])).to eq(note.show_ats["test"])
      end
    end

    it "returns localized notes when available" do
      @user.update_attribute :locale, "es"
      get "latest"
      expect(response).to have_http_status(:ok)
      res = response.parsed_body
      expect(res.length).to eq(1)

      json_note = res[0]
      expect(json_note["id"]).to eq(note.id)
      expect(json_note["title"]).to eq(note["es"][:title])
      expect(json_note["description"]).to eq(note["es"][:description])
      expect(json_note["url"]).to eq(note["es"][:url])
      expect(Time.zone.parse(json_note["date"])).to eq(note.show_ats["test"])
    end

    it "returns only published notes" do
      the_note = ReleaseNote.find(note.id)
      the_note.published = false
      the_note.save

      get "latest"
      expect(response).to have_http_status(:ok)
      res = response.parsed_body
      expect(res.length).to eq(0)

      the_note.published = true
      the_note.save

      get "latest"
      expect(response).to have_http_status(:ok)
      res = response.parsed_body
      expect(res.length).to eq(1)
    end

    it "returns only notes past their show_at" do
      the_note = ReleaseNote.find(note.id)
      the_note.set_show_at("test", Time.now.utc.change(usec: 0) + 1.hour)
      the_note.save

      get "latest"
      expect(response).to have_http_status(:ok)
      res = response.parsed_body
      expect(res.length).to eq(0)

      the_note.set_show_at("test", Time.now.utc.change(usec: 0) - 1.hour)
      the_note.save

      get "latest"
      expect(response).to have_http_status(:ok)
      res = response.parsed_body
      expect(res.length).to eq(1)
    end

    it "does not return notes that do not apply to the current user's roles" do
      user_session(account_admin_user)
      get "latest"
      expect(response).to have_http_status(:ok)
      res = response.parsed_body
      expect(res.length).to eq(0)
    end

    it "caches the dynamodb queries by language" do
      enable_cache do
        @user.update_attribute :locale, "es"
        # 2x the number of roles because we are testing two languages.
        # The second spanish request shouldn't call the method at all though
        expect(ReleaseNote).to receive(:latest).exactly(@user.roles(@student_enrollment.root_account).length * 2).times.and_call_original
        get "latest"
        get "latest"
        @user.update_attribute :locale, "en"
        get "latest"
      end
    end

    it "clears the new flag after the first request" do
      get "latest"
      res = response.parsed_body
      expect(res[0]["new"]).to be(true)
      get "latest"
      res = response.parsed_body
      expect(res[0]["new"]).to be(false)
    end
  end

  describe "unread_count" do
    before do
      @student_enrollment = student_in_course(active_all: true)
      user_session(@student_enrollment.user)

      the_note = ReleaseNote.find(note.id)
      the_note.published = true
      the_note.save
    end

    it "includes all notes if the user has seen none" do
      get "unread_count"
      res = response.parsed_body
      expect(res["unread_count"]).to eq(1)
    end

    it "includes no notes if the user has seen them all" do
      get "latest"
      get "unread_count"
      res = response.parsed_body
      expect(res["unread_count"]).to eq(0)
    end
  end
end
