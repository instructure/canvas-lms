# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe SmartSearchable do
  describe "#generate_embeddings" do
    before do
      skip "not available" unless ActiveRecord::Base.connection.table_exists?("wiki_page_embeddings")

      allow(SmartSearch).to receive(:generate_embedding).and_return([1] * 1536)
      expect(SmartSearch).to receive(:api_key).at_least(:once).and_return("fake_api_key")
    end

    before :once do
      course_factory
      @course.enable_feature! :smart_search
    end

    it "generates an embedding when creating a page" do
      wiki_page_model(title: "test", body: "foo")
      run_jobs
      expect(@page.reload.embeddings.count).to eq 1
    end

    it "replaces an embedding if it already exists" do
      wiki_page_model(title: "test", body: "foo")
      run_jobs
      @page.update body: "bar"
      run_jobs
      expect(@page.reload.embeddings.count).to eq 1
    end

    it "strips HTML from the body before indexing" do
      wiki_page_model(title: "test", body: "<ul><li>foo</li></ul>")
      expect(SmartSearch).to receive(:generate_embedding).with("test\n* foo")
      run_jobs
    end

    it "deletes embeddings when a page is deleted (and regenerates them when undeleted)" do
      wiki_page_model(title: "test", body: "foo")
      run_jobs
      @page.destroy
      expect(@page.reload.embeddings.count).to eq 0

      @page.restore
      run_jobs
      expect(@page.reload.embeddings.count).to eq 1
    end

    it "generates multiple embeddings for a page with long content" do
      wiki_page_model(title: "test", body: "foo" * 2000)
      run_jobs
      expect(@page.reload.embeddings.count).to eq 2
    end

    it "generates multiple embeddings and doesn't split words" do
      # 7997 bytes in total, would fit into two 4000-byte pages,
      # but word splitting will push it into 3
      wiki_page_model(title: "test", body: "testing123 " * 727)
      run_jobs
      expect(@page.reload.embeddings.count).to eq 3
    end
  end
end
