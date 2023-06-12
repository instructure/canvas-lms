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

describe BookmarkService do
  before :once do
    bookmark_service_model
  end

  context "post_bookmark" do
    before do
      # For safety, that we don't mess with external services at all.
      allow(@bookmark_service).to receive(:diigo_post_bookmark).and_return(true)
    end

    it "is able to post a bookmark for diigo" do
      expect(@bookmark_service.service).to eql("diigo")

      expect(Diigo::Connection).to receive(:diigo_post_bookmark).with(
        @bookmark_service,
        "google.com",
        "some title",
        "some comments",
        ["some", "tags"]
      ).and_return(true)

      @bookmark_service.post_bookmark(
        title: "some title",
        url: "google.com",
        comments: "some comments",
        tags: %w[some tags]
      )
    end

    it "rescues silently if something happens during the process" do
      allow(@bookmark_service).to receive(:diigo_post_bookmark).and_raise(ArgumentError)

      expect do
        @bookmark_service.post_bookmark(
          title: "some title",
          url: "google.com",
          comments: "some comments",
          tags: %w[some tags]
        )
      end.not_to raise_error
    end
  end
end
