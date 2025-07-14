# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Loaders::WikiPageLoaders do
  before(:once) do
    course_with_teacher(active_all: true)
    @wiki = @course.wiki
  end

  let(:context) { @course }

  describe "#perform" do
    before(:once) do
      # Create regular wiki pages
      @regular_page1 = @wiki.wiki_pages.create!(title: "Regular Page 1", body: "Content 1", context: @course)
      @regular_page2 = @wiki.wiki_pages.create!(title: "Regular Page 2", body: "Content 2", context: @course)

      # Create front page
      @front_page = @wiki.wiki_pages.create!(title: "Front Page", body: "Front page content", context: @course)
      @wiki.set_front_page_url!(@front_page.url)

      # Create page with permanent links (to test current_lookup)
      Account.site_admin.enable_feature!(:permanent_page_links)
      @page_with_lookup = @wiki.wiki_pages.create!(title: "Page With Lookup", body: "Lookup content", context: @course)
    end

    it "batch loads can_unpublish status correctly" do
      GraphQL::Batch.batch do
        loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)

        promises = [
          loader.load(@regular_page1.id),
          loader.load(@regular_page2.id),
          loader.load(@front_page.id),
          loader.load(@page_with_lookup.id)
        ]

        Promise.all(promises).then do |results|
          expect(results).to have(4).items
          expect(results[0]).to be(true)  # regular_page1 can be unpublished
          expect(results[1]).to be(true)  # regular_page2 can be unpublished
          expect(results[2]).to be(false) # front_page cannot be unpublished
          expect(results[3]).to be(true)  # page_with_lookup can be unpublished
        end
      end
    end

    it "returns true for regular pages" do
      GraphQL::Batch.batch do
        loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
        loader.load(@regular_page1.id).then do |result|
          expect(result).to be(true)
        end
      end
    end

    it "returns false for front page" do
      GraphQL::Batch.batch do
        loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
        loader.load(@front_page.id).then do |result|
          expect(result).to be(false)
        end
      end
    end

    it "handles pages with current_lookup correctly" do
      GraphQL::Batch.batch do
        loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
        loader.load(@page_with_lookup.id).then do |result|
          expect(result).to be(true)
        end
      end
    end

    it "handles non-existent page IDs gracefully" do
      non_existent_id = 999_999

      GraphQL::Batch.batch do
        loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
        loader.load(non_existent_id).then do |result|
          expect(result).to be(true) # Default to true if page doesn't exist
        end
      end
    end

    it "handles mixed existing and non-existent IDs" do
      non_existent_id = 999_999
      results = []

      GraphQL::Batch.batch do
        loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
        loader.load(@regular_page1.id).then { |result| results << result }
        loader.load(non_existent_id).then { |result| results << result }
        loader.load(@front_page.id).then { |result| results << result }
      end

      expect(results).to eq([true, true, false])
    end

    it "respects context-specific front page settings" do
      # Create another course with a different front page
      other_course = Course.create!(name: "Other Course")
      other_wiki = other_course.wiki
      other_page = other_wiki.wiki_pages.create!(title: "Other Front Page", body: "Other content", context: other_course)
      other_wiki.set_front_page_url!(other_page.url)

      GraphQL::Batch.batch do
        # Test original context
        original_loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)

        # Test other context
        other_loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(other_course)

        # Regular page in other context should be unpublishable
        other_regular = other_wiki.wiki_pages.create!(title: "Other Regular", body: "Other regular content", context: other_course)

        promises = [
          original_loader.load(@front_page.id),
          other_loader.load(other_page.id),
          other_loader.load(other_regular.id)
        ]

        Promise.all(promises).then do |results|
          expect(results).to eq([false, false, true]) # front pages can't be unpublished, regular page can
        end
      end
    end

    context "when permanent page links feature is disabled" do
      before do
        Account.site_admin.disable_feature!(:permanent_page_links)
      end

      after do
        Account.site_admin.enable_feature!(:permanent_page_links)
      end

      it "still works correctly without current_lookup" do
        regular_page = @wiki.wiki_pages.create!(title: "Test Page", body: "Test content", context: @course)

        GraphQL::Batch.batch do
          loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
          loader.load(regular_page.id).then do |result|
            expect(result).to be(true)
          end
        end
      end
    end

    context "with workflow states" do
      before(:once) do
        @deleted_page = @wiki.wiki_pages.create!(title: "Deleted Page", body: "Deleted content", context: @course)
        @deleted_page.destroy
      end

      it "handles deleted pages" do
        GraphQL::Batch.batch do
          loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
          loader.load(@deleted_page.id).then do |result|
            # Deleted pages should still be processed if found
            expect(result).to be(true)
          end
        end
      end
    end

    context "edge cases" do
      it "handles minimal page titles" do
        minimal_title_page = @wiki.wiki_pages.create!(title: "x", body: "Minimal title content", context: @course)

        GraphQL::Batch.batch do
          loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
          loader.load(minimal_title_page.id).then do |result|
            expect(result).to be(true)
          end
        end
      end

      it "handles pages with special characters in titles" do
        special_page = @wiki.wiki_pages.create!(title: "Special & Characters < >", body: "Special content", context: @course)

        GraphQL::Batch.batch do
          loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)
          loader.load(special_page.id).then do |result|
            expect(result).to be(true)
          end
        end
      end
    end

    context "performance" do
      it "efficiently handles large batches" do
        # Create many pages
        pages = []
        50.times do |i|
          pages << @wiki.wiki_pages.create!(title: "Batch Page #{i}", body: "Content #{i}", context: @course)
        end

        GraphQL::Batch.batch do
          loader = Loaders::WikiPageLoaders::CanUnpublishLoader.for(context)

          promises = pages.map { |page| loader.load(page.id) }

          Promise.all(promises).then do |results|
            expect(results).to all(be(true)) # All should be unpublishable
            expect(results).to have(50).items
          end
        end
      end
    end
  end
end
