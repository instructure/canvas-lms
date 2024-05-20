/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import EditConferenceView from 'ui/features/conferences/backbone/views/EditConferenceView'
import Conference from 'ui/features/conferences/backbone/models/Conference'
import timezone from 'timezone'
import tzInTest from '@canvas/datetime/specHelpers'
import french from 'timezone/fr_FR'
import fakeENV from 'helpers/fakeENV'

QUnit.module('EditConferenceView', {
  setup() {
    this.view = new EditConferenceView()
    this.datepickerSetting = {field: 'datepickerSetting', type: 'date_picker'}
    fakeENV.setup({
      conference_type_details: [{settings: [this.datepickerSetting]}],
      users: [
        {id: 1, name: 'Owlswick Clamp'},
        {id: 2, name: 'Abby Zollinger'},
        {id: 3, name: 'Bruce Young'},
      ],
      sections: [
        {id: 1, name: 'Section 1'},
        {id: 2, name: 'Section 2'},
      ],
      groups: [
        {id: 1, name: 'Study Group 1'},
        {id: 2, name: 'Study Group 2'},
      ],
      section_user_ids_map: {1: [1, 2], 2: [3]},
      group_user_ids_map: {1: [1], 2: [1, 2]},
    })
  },
  teardown() {
    this.view.$el.remove()
    fakeENV.teardown()
    tzInTest.restore()
  },
})

test('updateConferenceUserSettingDetailsForConference localizes values for datepicker settings', function () {
  tzInTest.configureAndRestoreLater({
    tz: timezone(french, 'fr_FR'),
    momentLocale: 'fr',
    formats: {'date.formats.full_with_weekday': '%a %-d %b, %Y %-k:%M'},
  })

  const conferenceData = {user_settings: {datepickerSetting: '2015-08-07T17:00:00Z'}}
  this.view.updateConferenceUserSettingDetailsForConference(conferenceData)
  equal(this.datepickerSetting.value, 'ven. 7 août, 2015 17:00')
})

test('#show sets the proper title for new conferences', function () {
  const expectedTitle = 'New Conference'
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  const conference = new Conference(attributes)
  this.view.show(conference)
  const title = this.view.$el.dialog('option', 'title')
  equal(title, expectedTitle)
})

test('#show sets the proper title for editing conferences', function () {
  const expectedTitle = 'Edit InstructureCon'
  const attributes = {
    title: 'InstructureCon',
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})
  const title = this.view.$el.dialog('option', 'title')
  equal(title, expectedTitle)
})

test('#show sets localized durataion when editing conference', function () {
  const expectedDuration = '1,234.5'
  const attributes = {
    title: 'InstructureCon',
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
    duration: 1234.5,
  }

  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})
  const duration = this.view.$('#web_conference_duration')[0].value
  equal(duration, expectedDuration)
})

test('"remove observers" modifies "invite all course members"', function () {
  const attributes = {
    title: 'Making Money',
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }
  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})
  ok(this.view.$('#members_list').is(':hidden'))
  ok(this.view.$('#observers_remove').is(':enabled'))

  this.view.$('#user_all').click()
  ok(this.view.$('#members_list').is(':visible'))
  ok(this.view.$('#observers_remove').is(':disabled'))
})

test('sections should appear in member list if course has more than one section', function () {
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  const conference = new Conference(attributes)
  this.view.show(conference)
  this.view.$('#user_all').click()
  ok(this.view.$('#section_1').is(':visible'))
  ok(this.view.$('#section_2').is(':visible'))
})

test('sections should not appear in member list if course has only section', function () {
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  window.ENV.sections = [{name: 'Section 1', id: 1}]

  const conference = new Conference(attributes)
  this.view.show(conference)
  this.view.$('#user_all').click()
  ok(!this.view.$('#section_1').is(':visible'))
})

test('groups should appear in member list if course has one or more groups', function () {
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  const conference = new Conference(attributes)
  this.view.show(conference)
  this.view.$('#user_all').click()
  ok(this.view.$('#group_1').is(':visible'))
})

test('checking/unchecking a section also checks/unchecks the members that are in that section', function () {
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  const conference = new Conference(attributes)
  this.view.show(conference)
  this.view.$('#user_all').click()
  this.view.$('#section_2').click()
  ok(!this.view.$('#user_1').is(':checked'))
  this.view.$('#section_1').click()
  ok(this.view.$('#user_1').is(':checked'))
  this.view.$('#section_1').click()
  ok(!this.view.$('#user_1').is(':checked'))
})

test('checking/unchecking a groups also checks/unchecks the members that are in that group', function () {
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  const conference = new Conference(attributes)
  this.view.show(conference)
  this.view.$('#user_all').click()
  ok(!this.view.$('#user_1').is(':checked'))
  this.view.$('#group_1').click()
  ok(this.view.$('#user_1').is(':checked'))
  this.view.$('#group_1').click()
  ok(!this.view.$('#user_1').is(':checked'))
})

test('unchecking a group only unchecks members that have not been selected by section also', function () {
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  const conference = new Conference(attributes)
  this.view.show(conference)
  this.view.$('#user_all').click()
  ok(!this.view.$('#user_1').is(':checked'))
  this.view.$('#group_1').click()
  this.view.$('#section_1').click()

  ok(this.view.$('#user_1').is(':checked'))
  ok(this.view.$('#user_2').is(':checked'))
  this.view.$('#group_1').click()
  ok(this.view.$('#user_1').is(':checked'))
})

test('unchecking a section only unchecks members that have not been selected by group also', function () {
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }

  const conference = new Conference(attributes)
  this.view.show(conference)
  this.view.$('#user_all').click()
  ok(!this.view.$('#user_1').is(':checked'))
  this.view.$('#group_1').click()
  this.view.$('#section_1').click()

  ok(this.view.$('#user_1').is(':checked'))
  ok(this.view.$('#user_2').is(':checked'))
  this.view.$('#section_1').click()
  ok(this.view.$('#user_1').is(':checked'))
  ok(!this.view.$('#user_2').is(':checked'))
})

test('While editing a conference the box for a group should be checked and disabled if everyone in the group is a participant', function () {
  const attributes = {
    title: 'Making Money',
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
    user_ids: [1],
  }
  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})

  ok(this.view.$('#group_1').is(':checked'))
  ok(this.view.$('#group_1').is(':disabled'))
})

test('While editing a conference the box for a section should be checked and disabled if everyone in the section is a participant', function () {
  const attributes = {
    title: 'Making Money',
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
    user_ids: [3],
  }
  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})

  ok(this.view.$('#section_2').is(':checked'))
  ok(this.view.$('#section_2').is(':disabled'))
})

test('While editing a conference unchecking a group should only uncheck members who are not a part of the existing conference', function () {
  const attributes = {
    title: 'Making Money',
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
    user_ids: [1],
  }
  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})
  ok(!this.view.$('#group_2').is(':checked'))
  ok(!this.view.$('#user_2').is(':checked'))

  this.view.$('#group_2').click()
  ok(this.view.$('#user_1').is(':checked'))
  ok(this.view.$('#user_2').is(':checked'))

  this.view.$('#group_2').click()
  ok(this.view.$('#user_1').is(':checked'))
  ok(!this.view.$('#user_2').is(':checked'))
})

test('While editing a conference unchecking a section should only uncheck member who are not a part of the existing conference', function () {
  const attributes = {
    title: 'Making Money',
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
    user_ids: [1],
  }
  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})
  ok(!this.view.$('#section_1').is(':checked'))
  ok(!this.view.$('#user_2').is(':checked'))

  this.view.$('#section_1').click()
  ok(this.view.$('#user_1').is(':checked'))
  ok(this.view.$('#user_2').is(':checked'))

  this.view.$('#section_1').click()
  ok(this.view.$('#user_1').is(':checked'))
  ok(!this.view.$('#user_2').is(':checked'))
})

test('while context_is_group = true no sections or groups should appear in the member list', function () {
  const attributes = {
    title: 'Making Money',
    recordings: [],
    user_settings: {
      scheduled_date: new Date(),
    },
    permissions: {
      update: true,
    },
  }
  window.ENV.context_is_group = true
  const conference = new Conference(attributes)
  this.view.show(conference)
  ok(!this.view.$('#section_1').is(':visible'))
  ok(!this.view.$('#section_2').is(':visible'))
  ok(!this.view.$('#group_1').is(':visible'))
  ok(!this.view.$('#group_2').is(':visible'))
})
