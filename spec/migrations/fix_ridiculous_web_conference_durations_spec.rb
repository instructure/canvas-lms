#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../spec_helper"
require 'db/migrate/20160805163609_fix_ridiculous_web_conference_durations.rb'

describe FixRidiculousWebConferenceDurations do
  it "sets ridiculously long conferences as long-running" do
    course_with_teacher
    allow(WebConference).to receive(:conference_types).and_return([{conference_type: 'test', class_name: 'WebConference'}])
    conf = course_factory.web_conferences.create!(user: @teacher, conference_type: 'test')
    conf.update_attribute(:duration, WebConference::MAX_DURATION + 1)
    FixRidiculousWebConferenceDurations.up
    expect(conf.reload.duration).to be_nil
  end
end
