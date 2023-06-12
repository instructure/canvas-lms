# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe Bookmarks::BookmarksController do
  context "when user is not logged in" do
    it "fails" do
      get "index", format: "json"
      assert_status(401)
    end
  end

  context "when user is logged in" do
    let(:u) { user_factory }
    let!(:bookmark) { Bookmarks::Bookmark.create(user_id: u.id, name: "bio 101", url: "/courses/1") }

    before do
      user_session(u)
    end

    describe "GET 'index'" do
      it "succeeds" do
        get "index", format: "json"
        expect(response).to be_successful
      end
    end

    describe "GET 'show'" do
      it "succeeds" do
        get "show", params: { id: bookmark.id }, format: "json"
        expect(response).to be_successful
      end

      it "includes data" do
        bookmark.update(data: { foo: "bar" })
        get "show", params: { id: bookmark.id }, format: "json"
        json = json_parse
        expect(json["data"]["foo"]).to eq("bar")
      end

      it "restricts to own bookmarks" do
        u2 = user_factory
        bookmark2 = Bookmarks::Bookmark.create(user_id: u2.id, name: "bio 101", url: "/courses/1")
        get "show", params: { id: bookmark2.id }, format: "json"
        expect(response).to_not be_successful
      end
    end

    describe "POST 'create'" do
      let(:params) { { name: "chem 101", url: "/courses/2" } }

      it "succeeds" do
        post "create", params:, format: "json"
        expect(response).to be_successful
      end

      it "creates a bookmark" do
        expect { post "create", params:, format: "json" }.to change { Bookmarks::Bookmark.count }.by(1)
      end

      it "sets user" do
        post "create", params:, format: "json"
        expect(Bookmarks::Bookmark.order(:id).last.user_id).to eq(u.id)
      end

      it "sets data" do
        post "create", params: params.merge(data: { foo: "bar" }), format: "json"
        expect(Bookmarks::Bookmark.order(:id).last.data["foo"]).to eq("bar")
      end

      it "appends by default" do
        post "create", params:, format: "json"
        expect(Bookmarks::Bookmark.order(:id).last).to be_last
      end

      it "sets position" do
        post "create", params: params.merge(position: 1), format: "json"
        expect(Bookmarks::Bookmark.order(:id).last).to_not be_last
      end

      it "handles position strings" do
        post "create", params: params.merge(position: "1"), format: "json"
        expect(Bookmarks::Bookmark.order(:id).last).to_not be_last
      end
    end

    describe "PUT 'update'" do
      it "succeeds" do
        put "update", params: { id: bookmark.id }, format: "json"
        expect(response).to be_successful
      end
    end

    describe "DELETE 'delete'" do
      it "succeeds" do
        delete "destroy", params: { id: bookmark.id }, format: "json"
        expect(response).to be_successful
      end
    end

    context "sharding" do
      specs_require_sharding

      it "does not asplode when creating a bookmark from a cross-shard institution" do
        @shard1.activate do
          cs_course = Course.create!(name: "cs_course", account: Account.create!)
          cs_course.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")

          post "create", params: { name: "chem 101", url: "/courses/2" }, format: "json"

          expect(response).to be_successful
        end
      end

      it "is created relative to the user's home shard" do
        @shard1.activate do
          cs_course = Course.create!(name: "cs_course", account: Account.create!)
          cs_course.enroll_user(@user, "TeacherEnrollment", enrollment_state: "active")

          post "create", params: { name: "chem 101", url: "/courses/2" }, format: "json"

          expect(response).to be_successful
          @json = response.parsed_body
        end
        bookmark = Bookmarks::Bookmark.find(@json["id"])
        expect(bookmark.user_id).to eq @user.id
      end
    end
  end
end
