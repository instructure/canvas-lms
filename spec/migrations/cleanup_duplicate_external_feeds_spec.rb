#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20141217222534_cleanup_duplicate_external_feeds'

describe 'CleanupDuplicateExternalFeeds' do
  before do
    @migration = CleanupDuplicateExternalFeeds.new
    @migration.down
  end

  it "should find duplicates" do
    c1 = course_model
    feeds = 3.times.map { external_feed_model({}, false) }
    feeds.each{ |f| f.save(validate: false) }
    feeds[2].update_attribute(:url, "http://another-non-default-place.com")

    c2 = course_model
    feeds << external_feed_model

    expect(ExternalFeed.where(id: feeds).count).to eq 4

    @migration.up

    expect(ExternalFeed.where(id: [feeds[0], feeds[2], feeds[3]]).count).to eq 3
    expect(ExternalFeed.where(id: feeds[1]).count).to eq 0
  end

  it "should cleanup associated entries and announcements of duplicates" do
    course_with_teacher
    @context = @course

    feeds = 2.times.map { external_feed_model({}, false) }
    feeds.each{ |f| f.save(validate: false) }
    entries = feeds.map do |feed|
      feed.external_feed_entries.create!(
        :user => @teacher,
        :title => 'blah',
        :message => 'blah',
        :workflow_state => :active
      )
    end
    announcements = feeds.map do |feed|
      a = announcement_model
      a.update_attribute(:external_feed_id, feed.id)
      a
    end

    @migration.up

    expect(ExternalFeed.where(id: feeds[0]).count).to eq 1
    expect(ExternalFeedEntry.where(id: entries[0]).count).to eq 1
    expect(announcements[0].reload.external_feed_id).to eq feeds[0].id

    expect(ExternalFeed.where(id: feeds[1]).count).to eq 0
    expect(ExternalFeedEntry.where(id: entries[1]).count).to eq 0
    expect(announcements[1].reload.external_feed_id).to eq feeds[0].id
  end

  it "sets a default for any NULL verbosity field" do
    course = course_model
    feed = external_feed_model
    ExternalFeed.where(id: feed).update_all(verbosity: nil)

    @migration.up

    expect(feed.reload.verbosity).to eq 'full'
  end
end
