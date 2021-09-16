# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe DiscussionEntryParticipant do
  describe 'create' do
    before(:once) do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @topic = @course.discussion_topics.create(:title => "some topic")
      @entry = @topic.discussion_entries.create(:message => "some message", :user => @student)
      @participant = @entry.find_existing_participant(@student)
    end

    it 'sets the root account id from the discussion_topic_entry' do
      expect(@participant.root_account_id).to eq(@entry.root_account_id)
    end
  end
end