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

import 'jquery-migrate'
import EditConferenceView from '../EditConferenceView'
import Conference from '../../models/Conference'
import timezone from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import french from 'timezone/fr_FR'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('EditConferenceView', () => {
  let view
  let datepickerSetting

  beforeEach(() => {
    view = new EditConferenceView()
    datepickerSetting = {field: 'datepickerSetting', type: 'date_picker'}
    fakeENV.setup({
      conference_type_details: [{settings: [datepickerSetting]}],
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
  })

  afterEach(() => {
    view.$el.remove()
    fakeENV.teardown()
    tzInTest.restore()
  })

  test('updateConferenceUserSettingDetailsForConference localizes values for datepicker settings', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(french, 'fr_FR'),
      momentLocale: 'fr',
      formats: {'date.formats.full_with_weekday': '%a %-d %b, %Y %-k:%M'},
    })

    const conferenceData = {user_settings: {datepickerSetting: '2015-08-07T17:00:00Z'}}
    view.updateConferenceUserSettingDetailsForConference(conferenceData)
    expect(datepickerSetting.value).toBe('ven. 7 août, 2015 17:00')
  })

  test('#show sets the proper title for new conferences', () => {
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
    view.show(conference)
    const title = view.$el.dialog('option', 'title')
    expect(title).toBe(expectedTitle)
  })

  test('#show sets the proper title for editing conferences', () => {
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
    view.show(conference, {isEditing: true})
    const title = view.$el.dialog('option', 'title')
    expect(title).toBe(expectedTitle)
  })

  test('#show sets localized duration when editing conference', () => {
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
    view.show(conference, {isEditing: true})
    const duration = view.$('#web_conference_duration')[0].value
    expect(duration).toBe(expectedDuration)
  })

  // fails in QUnit, passes in Jest
  test.skip('"remove observers" modifies "invite all course members"', () => {
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
    view.show(conference, {isEditing: true})
    expect(view.$('#members_list').is(':hidden')).toBe(true)
    expect(view.$('#observers_remove').is(':enabled')).toBe(true)

    view.$('#user_all').click()
    expect(view.$('#members_list').is(':visible')).toBe(true)
    expect(view.$('#observers_remove').is(':disabled')).toBe(true)
  })

  // passes in Jest, fails in QUnit
  test.skip('sections should appear in member list if course has more than one section', () => {
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
    view.show(conference)
    view.$('#user_all').click()
    expect(view.$('#section_1').is(':visible')).toBe(true)
    expect(view.$('#section_2').is(':visible')).toBe(true)
  })

  test('sections should not appear in member list if course has only one section', () => {
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
    view.show(conference)
    view.$('#user_all').click()
    expect(view.$('#section_1').is(':visible')).toBe(false)
  })

  // fails in QUnit, passes in Jest
  test.skip('groups should appear in member list if course has one or more groups', () => {
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
    view.show(conference)
    view.$('#user_all').click()
    expect(view.$('#group_1').is(':visible')).toBe(true)
  })

  test('checking/unchecking a section also checks/unchecks the members that are in that section', () => {
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
    view.show(conference)
    view.$('#user_all').click()
    view.$('#section_2').click()
    expect(view.$('#user_1').is(':checked')).toBe(false)
    view.$('#section_1').click()
    expect(view.$('#user_1').is(':checked')).toBe(true)
    view.$('#section_1').click()
    expect(view.$('#user_1').is(':checked')).toBe(false)
  })

  test('checking/unchecking a group also checks/unchecks the members that are in that group', () => {
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
    view.show(conference)
    view.$('#user_all').click()
    expect(view.$('#user_1').is(':checked')).toBe(false)
    view.$('#group_1').click()
    expect(view.$('#user_1').is(':checked')).toBe(true)
    view.$('#group_1').click()
    expect(view.$('#user_1').is(':checked')).toBe(false)
  })

  test('unchecking a group only unchecks members that have not been selected by section also', () => {
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
    view.show(conference)
    view.$('#user_all').click()
    expect(view.$('#user_1').is(':checked')).toBe(false)
    view.$('#group_1').click()
    view.$('#section_1').click()

    expect(view.$('#user_1').is(':checked')).toBe(true)
    expect(view.$('#user_2').is(':checked')).toBe(true)
    view.$('#group_1').click()
    expect(view.$('#user_1').is(':checked')).toBe(true)
  })

  test('unchecking a section only unchecks members that have not been selected by group also', () => {
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
    view.show(conference)
    view.$('#user_all').click()
    expect(view.$('#user_1').is(':checked')).toBe(false)
    view.$('#group_1').click()
    view.$('#section_1').click()

    expect(view.$('#user_1').is(':checked')).toBe(true)
    expect(view.$('#user_2').is(':checked')).toBe(true)
    view.$('#section_1').click()
    expect(view.$('#user_1').is(':checked')).toBe(true)
    expect(view.$('#user_2').is(':checked')).toBe(false)
  })

  test('While editing a conference the box for a group should be checked and disabled if everyone in the group is a participant', () => {
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
    view.show(conference, {isEditing: true})

    expect(view.$('#group_1').is(':checked')).toBe(true)
    expect(view.$('#group_1').is(':disabled')).toBe(true)
  })

  test('While editing a conference the box for a section should be checked and disabled if everyone in the section is a participant', () => {
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
    view.show(conference, {isEditing: true})

    expect(view.$('#section_2').is(':checked')).toBe(true)
    expect(view.$('#section_2').is(':disabled')).toBe(true)
  })

  test('While editing a conference unchecking a group should only uncheck members who are not a part of the existing conference', () => {
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
    view.show(conference, {isEditing: true})
    expect(view.$('#group_2').is(':checked')).toBe(false)
    expect(view.$('#user_2').is(':checked')).toBe(false)

    view.$('#group_2').click()
    expect(view.$('#user_1').is(':checked')).toBe(true)
    expect(view.$('#user_2').is(':checked')).toBe(true)

    view.$('#group_2').click()
    expect(view.$('#user_1').is(':checked')).toBe(true)
    expect(view.$('#user_2').is(':checked')).toBe(false)
  })

  test('While editing a conference unchecking a section should only uncheck members who are not a part of the existing conference', () => {
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
    view.show(conference, {isEditing: true})
    expect(view.$('#section_1').is(':checked')).toBe(false)
    expect(view.$('#user_2').is(':checked')).toBe(false)

    view.$('#section_1').click()
    expect(view.$('#user_1').is(':checked')).toBe(true)
    expect(view.$('#user_2').is(':checked')).toBe(true)

    view.$('#section_1').click()
    expect(view.$('#user_1').is(':checked')).toBe(true)
    expect(view.$('#user_2').is(':checked')).toBe(false)
  })

  test('while context_is_group = true no sections or groups should appear in the member list', () => {
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
    view.show(conference)
    expect(view.$('#section_1').is(':visible')).toBe(false)
    expect(view.$('#section_2').is(':visible')).toBe(false)
    expect(view.$('#group_1').is(':visible')).toBe(false)
    expect(view.$('#group_2').is(':visible')).toBe(false)
  })
})
