# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe WikiPageLookup do
  context "relationship with WikiPage" do
    before :once do
      course_factory
      @page = @course.wiki_pages.create!(title: "Cool page")
      @lookup1 = @page.current_lookup
      @lookup2 = @page.wiki_page_lookups.create!(slug: "an-old-url-2")
      @lookup3 = @page.wiki_page_lookups.create!(slug: "an-old-url-3")
    end

    it "sets context based off wiki page" do
      expect(@lookup1.context_id).to eq @course.id
      expect(@lookup1.context_type).to eq "Course"
    end

    it "cannot be deleted if it is the current lookup" do
      expect { @lookup1.destroy }.to raise_error(ActiveRecord::InvalidForeignKey)
      expect { @lookup1.delete }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "can be deleted if it is not the current lookup" do
      @lookup2.destroy
      expect { WikiPageLookup.find(@lookup2.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(@page.wiki_page_lookups.pluck(:id)).to match_array([@lookup1.id, @lookup3.id])
      expect { @page.reload }.not_to raise_error
    end

    it "is not deleted when page is soft-deleted" do
      @page.destroy
      expect { @page.reload }.not_to raise_error
      expect(@page.workflow_state).to eq "deleted"
      expect(@page.wiki_page_lookups.count).to be 3
      [@lookup1, @lookup2, @lookup3].each do |record|
        expect { record.reload }.not_to raise_error
      end
    end

    it "is deleted when page is hard-deleted" do
      @page.destroy_permanently!
      [@page, @lookup1, @lookup2, @lookup3].each do |record|
        expect { record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "is restored when a page is un-deleted" do
      @page.destroy
      @page.restore
      @page.reload
      expect(@page.workflow_state).to eq "unpublished"
      expect(@page.wiki_page_lookups.count).to be 3
      expect(@page.current_lookup.slug).to eq "cool-page"
    end
  end

  context "slug uniqueness" do
    before :once do
      course_factory
      @page = @course.wiki_pages.create!(title: "Test")
    end

    it "is required within a context" do
      first_lookup = @page.current_lookup
      second_lookup = first_lookup.dup
      expect { second_lookup.save }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "is not required across different contexts" do
      group = Group.create!(name: "Example Group", context: @course)
      expect { group.wiki_pages.create!(title: @page.title) }.not_to raise_error
      second_lookup = group.wiki_pages.last.current_lookup
      expect(second_lookup.slug).to eq "test"
    end
  end
end
