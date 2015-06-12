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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'nokogiri'

describe CanvasConnect::MeetingArchive do

  class MockClient
    def sco_contents(*args)
      Nokogiri::XML('<?xml version="1.0" encoding="utf-8"?>
          <results>
            <status code="ok"/>
            <scos>
              <sco sco-id="38230" source-sco-id="" folder-id="38223" type="content" icon="archive" display-seq="0" duration="0" is-folder="0">
                <name>Test Recording</name>
                <url-path>/p3u8rj0rvuj/</url-path>
                <date-begin>2013-09-05T12:13:03.387-06:00</date-begin>
                <date-end>2013-09-05T12:13:28.970-06:00</date-end>
                <date-created>2013-09-05T12:13:03.387-06:00</date-created>
                <date-modified>2013-09-05T12:13:29.727-06:00</date-modified>
              </sco>
              <sco>
              </sco>
            </scos>
          </results>')
    end
  end

  subject { CanvasConnect::MeetingArchive.retrieve(38230, MockClient.new).first }

  it "returns the correct number" do
    expect(CanvasConnect::MeetingArchive.retrieve(38230, MockClient.new).count).to eq 2
  end

  it "returns the name" do
    expect(subject.name).to eq 'Test Recording'
  end

  it "returns the url_path" do
    expect(subject.url_path).to eq '/p3u8rj0rvuj/'
  end

  it "returns the date_begin" do
    expect(subject.date_begin).to eq '2013-09-05T12:13:03.387-06:00'
  end

  it "returns the date end" do
    expect(subject.date_end).to eq '2013-09-05T12:13:28.970-06:00'
  end

  it "returns the date created" do
    expect(subject.date_created).to eq '2013-09-05T12:13:03.387-06:00'
  end

  it "returns the date modified" do
    expect(subject.date_modified).to eq '2013-09-05T12:13:29.727-06:00'
  end

end