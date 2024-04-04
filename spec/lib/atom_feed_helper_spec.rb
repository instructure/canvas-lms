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

class BadKeyModel
  def to_atom
    { bad_key: :bad_value }
  end
end

class SimpleModel
  def to_atom(entry_title:)
    { title: entry_title, link: "link", updated: Time.now }
  end
end

class ComplexModel
  def initialize(test)
    @test = test
  end

  def to_atom
    {
      title: @test.custom_entry_title,
      author: @test.custom_entry_author,
      updated: @test.custom_entry_updated,
      published: @test.custom_entry_published,
      id: @test.custom_entry_id,
      link: @test.custom_entry_link,
      content: @test.custom_entry_content,
      attachment_links: @test.custom_entry_attachment_links
    }
  end
end

describe AtomFeedHelper do
  let(:title) { "Feed Title" }
  let(:link) { "https://www.example.com/feed/atom.xml" }
  let(:ns) { { "atom" => "http://www.w3.org/2005/Atom" } }
  let(:entries) { [] }
  let(:updated) { Time.now }

  let(:custom_entry_author) { "custom_entry_author" }
  let(:custom_entry_title) { "custom_entry_title" }
  let(:custom_entry_updated) { 1.year.ago }
  let(:custom_entry_published) { 2.years.ago }
  let(:custom_entry_id) { "custom_entry_id" }
  let(:custom_entry_link) { "https://www.example.com/entry_1" }
  let(:custom_entry_content) { "<strong>Content</strong>" }
  let(:custom_entry_attachment_links) { ["https://www.example.com/attachment_1", "https://www.example.com/attachment_2"] }

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

  it "does not permit unknown keys in the entries hash" do
    expect { described_class.render_xml(title:, link:, entries: [BadKeyModel.new]) }.to raise_exception(/unknown key/)
  end

  it "passes along additional kwargs to the to_atom method" do
    xml = described_class.render_xml(title:, link:, entries: [SimpleModel.new], entry_title: custom_entry_title)
    expect(Feedjira.parse(xml.to_s).entries.first.title).to eq(custom_entry_title)

    xml = described_class.render_xml(title:, link:, entries: [SimpleModel.new]) { { entry_title: custom_entry_title } }
    expect(Feedjira.parse(xml.to_s).entries.first.title).to eq(custom_entry_title)
  end

  it "parses supported entry attributes into the XML" do
    xml = described_class.render_xml(title:, link:, entries: [ComplexModel.new(self)])
    feed = Feedjira.parse(xml.to_s)

    expect(feed.entries.first.title).to eq(custom_entry_title)
    expect(feed.entries.first.author).to eq(custom_entry_author)
    expect(feed.entries.first.published).to eq(custom_entry_published.rfc3339)
    expect(feed.entries.first.links.first).to eq(custom_entry_link)
    expect(feed.entries.first.content).to eq(custom_entry_content)

    expect(xml.xpath("//atom:entry/atom:updated", ns)&.text).to eq(custom_entry_updated.rfc3339)
    expect(xml.xpath("//atom:entry/atom:id", ns)&.text).to eq(custom_entry_id)
    expect(xml.xpath("//atom:entry/atom:link[@rel='enclosure']", ns)&.map(&:attributes)&.map { |a| a["href"].value }).to eq(custom_entry_attachment_links)
  end
end
