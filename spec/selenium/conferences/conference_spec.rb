#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe 'Web conferences' do
  include_context 'in-process server selenium tests'
  include ConferencesCommon
  include WebMock::API

  before(:once) do
    initialize_wimba_conference_plugin
    course_with_teacher(name: 'Teacher Bob', active_all: true)
    course_with_ta(name: 'TA Alice', course: @course, active_all: true)
    4.times do |i|
      course_with_student(name: "Student_#{i + 1}", course: @course, active_all: true)
    end
  end

  before(:each) do
    user_session(@teacher)
    get conferences_index_page
    stub_request(:get, /wimba\.instructure\.com/)
  end

  after { close_extra_windows }

  context 'when creating a conference' do
    it 'invites a subset of users', priority: "1", test_id: 273639 do
      skip_if_safari(:alert)
      conference_title = 'Private Conference by Invitation Only'
      create_conference(title: conference_title, invite_all_users: false)
      verify_conference_list_includes(conference_title)
    end

    it 'invites all the course users', priority: "1", test_id: 273640 do
      skip_if_safari(:alert)
      conference_title = 'Course Conference'
      create_conference(title: conference_title, invite_all_users: true)
      verify_conference_list_includes(conference_title)
    end

    it 'includes observers in manual invite', priority: "1", test_id: 3255709 do
      skip_if_safari(:alert)
      course_with_observer(name: 'Observer Kim', course: @course, active_all: true)
      get conferences_index_page
      new_conference_button.click
      f('.all_users_checkbox').click
      expect(f('#members_list')).to include_text('Kim, Observer')
    end
  end

  context 'when concluding a conference' do
    let(:conference_title) { 'Newer Conference' }
    before(:once) do
      conference = create_wimba_conference(conference_title)
      conference.add_attendee(@user)
    end

    context 'as a teacher' do
      it 'concludes the conference', priority: "1", test_id: 323320 do
        end_first_conference_in_list
        verify_conference_list_is_empty
        verify_concluded_conference_list_includes(conference_title)
      end

      it 'should not treat the concluded conference as active', priority: "2", test_id: 1041396 do
        end_first_conference_in_list
        refresh_page
        expect(f('#new-conference-list .emptyMessage').text).to include('There are no new conferences')
      end
    end

    context 'as a TA invited to the conference' do
      before(:each) do
        user_session(@ta)
        get conferences_index_page
      end

      it 'concludes the conference', priority: "1", test_id: 323319 do
        end_first_conference_in_list
        verify_conference_list_is_empty
        verify_concluded_conference_list_includes(conference_title)
      end
    end
  end

  context 'when no conferences exist' do
    it 'should display initial elements of the conference page', priority: "1", test_id: 118488 do
      skip_if_safari(:alert)
      expect(new_conference_button).to be

      headers = ff('.element_toggler')
      expect(headers[0]).to include_text('New Conferences')
      verify_conference_list_is_empty

      expect(headers[1]).to include_text('Concluded Conferences')
      verify_concluded_conference_list_is_empty
    end

    it 'should create a web conference', priority: "1", test_id: 118489 do
      skip_if_safari(:alert)
      conference_title = 'A New Web Conference'
      create_conference(title: conference_title, invite_all_users: true)
      verify_conference_list_includes(conference_title)
    end

    it 'should cancel creating a web conference', priority: "2", test_id: 581092 do
      skip_if_safari(:alert)
      create_conference(cancel: true)
      expect(f('#add_conference_form')).not_to be_displayed
      verify_conference_list_is_empty
    end
  end

  context 'when one conference exists' do
    before(:once) { @conference = create_wimba_conference('A Conference', 1234) }

    context 'when the conference is open' do
      it 'should delete active conferences', priority: "1", test_id: 126912 do
        delete_conference
        verify_conference_list_is_empty
      end

      it 'should set focus to the Add Conference button if there are no preceeding conferences', priority: "2" do
        delete_conference
        check_element_has_focus(new_conference_button)
      end

      it 'should set focus to the cog menu if the delete was cancelled', priority: "2" do
        cog_menu_item = f('.al-trigger')
        delete_conference(cog_menu_item: cog_menu_item, cancel: true)
        check_element_has_focus(cog_menu_item)
      end

      it 'should open editor if edit selected from cog menu', priority: "2" do
        cog_menu_item = f('.al-trigger')
        edit_conference(cog_menu_item: cog_menu_item, cancel: false)

        duration_edit_field = f('#web_conference_duration');

        expect(duration_edit_field).to be_displayed # input field w/in editor
        # value is localized
        expect(duration_edit_field.attribute('value')).to eq('1,234')
      end
    end

    context 'when the conference is concluded' do
      before(:once) { conclude_conference(@conference) }

      it 'should delete concluded conferences', priority: "2", test_id: 163991 do
        delete_conference
        verify_concluded_conference_list_is_empty
      end
    end
  end

  context 'when two conferences exist' do
    before(:once) do
      create_wimba_conference('First Wimba Conference')
      create_wimba_conference('Second Wimba Conference')
    end

    it 'should set focus to the preceding conference\'s cog after deleting', priority: "2" do
      settings_triggers = ff('.al-trigger')
      delete_conference(cog_menu_item: settings_triggers.last)
      check_element_has_focus(settings_triggers.first)
    end
  end
end
