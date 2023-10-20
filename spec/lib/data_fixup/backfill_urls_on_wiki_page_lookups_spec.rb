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

describe DataFixup::BackfillUrlsOnWikiPageLookups do
  before(:once) do
    course_factory
    @wp1 = @course.wiki_pages.create!(title: "test1")
    @wp2 = @course.wiki_pages.create!(title: "test2")
    @wp3 = @course.wiki_pages.create!(title: "test3")
    @wp4 = @course.wiki_pages.create!(title: "test4")

    @wpl1 = @wp1.current_lookup
    @wpl2 = @wp2.current_lookup
    @wpl3 = @wp3.current_lookup
    @wpl4 = @wp4.current_lookup

    # remove some of the lookups
    @wp1.update_attribute(:current_lookup_id, nil)
    @wp2.update_attribute(:current_lookup_id, nil)
    @wp4.update_attribute(:current_lookup_id, nil)
    @wpl1.destroy
    @wpl2.destroy
    @wpl4.destroy

    @wp5 = @course.wiki_pages.create!(title: "the-same")
    @wp6 = @course.wiki_pages.create!(title: "the-same")

    @wpl5 = @wp5.current_lookup
    @wpl6 = @wp6.current_lookup
  end

  it "creates a wiki_page_lookup if one does not exist" do
    described_class.run(@wp1.id, @wp2.id)

    expect(@wp1.reload.current_lookup_id).to_not be_nil
    expect(@wp2.reload.current_lookup_id).to_not be_nil
    expect(@wp1.wiki_page_lookups.count).to be 1
    expect(@wp2.wiki_page_lookups.count).to be 1
  end

  it "doesn't update pages not between the start and end id" do
    described_class.run(@wp1.id, @wp2.id)

    expect(@wp1.reload.current_lookup_id).to_not be_nil
    expect(@wp2.reload.current_lookup_id).to_not be_nil
    expect(@wp1.wiki_page_lookups.count).to be 1
    expect(@wp2.wiki_page_lookups.count).to be 1

    expect(@wp4.reload.current_lookup_id).to be_nil
    expect(@wp4.wiki_page_lookups.count).to be 0
  end

  it "does not perform insert when WikiPage current_lookup_id is not nil" do
    described_class.run(@wp3.id, @wp3.id)

    expect(@wp3.reload.current_lookup_id).to be @wpl3.id
    expect(@wp3.wiki_page_lookups.count).to be 1
  end

  it "does not perform insert on deleted WikiPage" do
    @wp3.destroy
    expect(@wp3.workflow_state).to eq "deleted"
    described_class.run(@wp3.id, @wp3.id)

    expect(@wp3.reload.current_lookup_id).to be_nil
    expect { @wpl3.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(@wp3.wiki_page_lookups.count).to be 0
  end

  it "handles duplicate urls in the same batch" do
    @wp5.update_attribute(:current_lookup_id, nil)
    @wp6.update_attribute(:current_lookup_id, nil)
    @wpl5.destroy
    @wpl6.destroy

    @wp6.update_attribute(:url, "the-same")

    described_class.run(@wp5.id, @wp6.id)

    expect(@wp5.reload.current_lookup_id).to_not be_nil
    expect(@wp6.reload.current_lookup_id).to_not be_nil
    expect(@wp5.wiki_page_lookups.count).to be 1
    expect(@wp6.wiki_page_lookups.count).to be 1

    expect(@wp5.current_lookup.slug).to eq "page_id:#{@wp5.id}"
    expect(@wp6.current_lookup.slug).to eq "page_id:#{@wp6.id}"
  end

  it "handles duplicate urls in a different batch" do
    @wp6.update_attribute(:current_lookup_id, nil)
    @wpl6.destroy

    @wp6.update_attribute(:url, "the-same")

    described_class.run(@wp6.id, @wp6.id)

    expect(@wp6.reload.current_lookup_id).to_not be_nil
    expect(@wp6.wiki_page_lookups.count).to be 1

    expect(@wp5.reload.current_lookup.slug).to eq("page_id:#{@wp5.id}")
    expect(@wp6.current_lookup.slug).to eq("the-same")
  end
end
