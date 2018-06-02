#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/conferences_common'
require_relative '../helpers/public_courses_context'

describe 'BigBlueButton conferences' do
  include_context 'in-process server selenium tests'
  include ConferencesCommon
  include WebMock::API

  bbb_endpoint = 'bbb.blah.com'
  bbb_secret = 'mock-secret'
  bbb_fixtures = {
    :get_recordings => {
      'meetingID' => 'instructure_web_conference_3Fn2k10wu0jK7diwJHs2FkDU0oXyX1ErUZCavikc',
      'checksum' => '9f41063382ab155ccf75fe2f212846e3bb103579'
    },
    :delete_recordings => {
      'recordID' => '0225ccf234655ae60658ccac1e272d48781b491c-1511812307014',
      'checksum' => '4aefca80ba80ba3d540295ea3e88215df77cf5cf'
    }
  }

  before(:once) do
    initialize_big_blue_button_conference_plugin bbb_endpoint, bbb_secret
    course_with_teacher(name: 'Teacher Bob', active_all: true)
    course_with_ta(name: 'TA Alice', course: @course, active_all: true)
    course_with_student(name: "Student John", course: @course, active_all: true)
  end

  before(:each) do
    user_session(@teacher)
    get conferences_index_page
  end

  after { close_extra_windows }
  context 'when a conference is open' do

    context 'and the conference has no recordings' do
      before(:once) do
        stub_request(:get, /getRecordings/).
          with(query: bbb_fixtures[:get_recordings]).
          to_return(:body => big_blue_button_mock_response('get_recordings', 'none'))
        @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]['meetingID'])
      end

      it 'should not include list with recordings', priority: '2' do
        verify_conference_does_not_include_recordings
      end
    end

    context 'and the conference has recordings' do
      before(:once) do
        stub_request(:get, /getRecordings/).
          with(query: bbb_fixtures[:get_recordings]).
          to_return(:body => big_blue_button_mock_response('get_recordings', 'two'))
        @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]['meetingID'])
      end

      it 'should include list with recordings', priority: '2' do
        verify_conference_includes_recordings
      end
    end

    context 'and the conference has one recording and it is deleted' do
      before(:once) do
        stub_request(:get, /deleteRecordings/).
          with(query: bbb_fixtures[:delete_recordings]).
          to_return(:body => big_blue_button_mock_response('delete_recordings'))
        stub_request(:get, /getRecordings/).
          with(query: bbb_fixtures[:get_recordings]).
          to_return(:body => big_blue_button_mock_response('get_recordings', 'one'))
        @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]['meetingID'])
      end

      it 'should remove recording from the list', priority: '2' do
        show_recordings_in_first_conference_in_list
        delete_first_recording_in_first_conference_in_list
        verify_conference_does_not_include_recordings
      end
    end

    context 'and the conference has one recording with statistics' do
      before(:once) do
        stub_request(:get, /getRecordings/).
          with(query: bbb_fixtures[:get_recordings]).
          to_return(:body => big_blue_button_mock_response('get_recordings', 'one'))
        @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]['meetingID'])
      end

      it 'teacher should see link for statistics', priority: '2' do
        show_recordings_in_first_conference_in_list
        verify_conference_includes_recordings_with_statistics
      end
    end

    context 'and the conference has one recording with statistics' do
      before(:once) do
        stub_request(:get, /getRecordings/).
          with(query: bbb_fixtures[:get_recordings]).
          to_return(:body => big_blue_button_mock_response('get_recordings', 'one'))
        @conference = create_big_blue_button_conference(bbb_fixtures[:get_recordings]['meetingID'])
        @conference.add_user(@student, 'attendee')
      end

      it 'student should not see link for statistics', priority: '2' do
        user_session(@student)
        get conferences_index_page
        show_recordings_in_first_conference_in_list
        verify_conference_does_not_include_recordings_with_statistics
      end
    end

  end
end
