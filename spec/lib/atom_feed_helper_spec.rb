# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require "feedjira"

describe AtomFeedHelper do
  let(:title) { "Feed Title" }
  let(:link) { "https://www.example.com/feed/atom.xml" }
  let(:ns) { { "atom" => "http://www.w3.org/2005/Atom" } }
  let(:entries) { [] }
  let(:updated) { Time.now }

  around do |example|
    Timecop.freeze(updated, &example)
  end

  it "renders the block as an atom-format XML" do
    xml = described_class.render_xml(title:, link:, entries:)
    feed = Feedjira.parse(xml.to_s)

    expect(feed.feed_url).to eq(link)
    expect(feed.title).to eq(title)
    expect(xml.xpath("//atom:id", ns)&.text).to eq(link)
    expect(xml.xpath("//atom:updated", ns)&.text).to eq(updated.rfc3339)
  end

  it "allows an overridden value for updated and id" do
    custom_id = "custom_id"
    custom_updated = 1.year.from_now

    xml = Timecop.freeze(custom_updated) do
      described_class.render_xml(title:, link:, entries:, updated: custom_updated, id: custom_id)
    end
    feed = Feedjira.parse(xml.to_s)

    expect(feed.feed_url).to eq(link)
    expect(feed.title).to eq(title)
    expect(xml.xpath("//atom:id", ns)&.text).to eq(custom_id)
    expect(xml.xpath("//atom:updated", ns)&.text).to eq(custom_updated.rfc3339)
  end
end
