#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Api::V1::CourseEvent do
  include Api::V1::CourseEvent

  def url_root
    'http://www.example.com'
  end

  def api_v1_course_url(course)
    URI.encode("#{url_root}/api/v1/courses/#{course}")
  end

  def feeds_calendar_url(feed_code)
    "feed_calendar_url(#{feed_code.inspect})"
  end

  def service_enabled?(type)
    false
  end

  before do
    skip("needs auditors cassandra keyspace configured") unless Auditors::Course::Stream.available?

    @request_id = SecureRandom.uuid
    RequestContextGenerator.stubs( :request_id => @request_id )

    @domain_root_account = Account.default

    course_with_teacher(account: @domain_root_account)

    @page_view = PageView.new { |p|
      p.assign_attributes({
        :request_id => @request_id,
        :remote_ip => '10.10.10.10'
      })
    }

    PageView.stubs(
      :find_by_id => @page_view,
      :find_all_by_id => [ @page_view ]
    )

    @events = []
    (1..5).each do |index|
      @course.name = "Course #{index}"
      @course.start_at = Date.today + index.days
      @course.conclude_at = @course.start_at + 7.days

      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes, source: :api)
      @events << @event
    end
  end

  it "should be formatted as a course content event hash" do
    event = course_event_json(@event, @student, @session)

    expect(event[:id]).to eq @event.id
    expect(event[:created_at]).to eq @event.created_at.in_time_zone
    expect(event[:event_type]).to eq @event.event_type
    expect(event[:event_data]).to eq @event.event_data
    expect(event[:event_source]).to eq @event.event_source

    expect(event[:links].keys.sort).to eq [:course, :page_view, :sis_batch, :user]

    expect(event[:links][:course]).to eq Shard.relative_id_for(@course, Shard.current, Shard.current)
    expect(event[:links][:page_view]).to eq @page_view.id
    expect(event[:links][:user]).to eq Shard.relative_id_for(@teacher, Shard.current, Shard.current)
  end

  it "should be formatted as an array of course content event hashes" do
    expect(course_events_json(@events, @student, @session).size).to eql(@events.size)
  end

  it "should be formatted as an array of compound course content event hashes" do
    json_hash = course_events_compound_json(@events, @user, @session)

    expect(json_hash.keys.sort).to eq [:events, :linked, :links]

    expect(json_hash[:links]).to eq({
      "events.course" => "#{url_root}/api/v1/courses/{events.course}",
      "events.user" => nil,
      "events.sis_batch" => nil
    })

    expect(json_hash[:events]).to eq course_events_json(@events, @user, @session)

    linked = json_hash[:linked]
    expect(linked.keys.sort).to eq [:courses, :page_views, :users]
    expect(linked[:courses].size).to eql(1)
    expect(linked[:users].size).to eql(1)
    expect(linked[:page_views].size).to eql(1)
  end

  it "should handle an empty result set" do
    json_hash = course_events_compound_json([], @user, @session)

    expect(json_hash.keys.sort).to eq [:events, :linked, :links]
    expect(json_hash[:events]).to eq course_events_json([], @user, @session)

    linked = json_hash[:linked]
    expect(linked.keys.sort).to eq [:courses, :page_views, :users]
    expect(linked[:courses].size).to be_zero
    expect(linked[:users].size).to be_zero
    expect(linked[:page_views].size).to be_zero
  end
end
