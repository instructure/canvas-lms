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

import EditConferenceView from 'compiled/views/conferences/EditConferenceView'
import Conference from 'compiled/models/Conference'
import tz from 'timezone'
import french from 'timezone/fr_FR'
import I18nStubber from 'helpers/I18nStubber'
import fakeENV from 'helpers/fakeENV'

QUnit.module('EditConferenceView', {
  setup() {
    this.view = new EditConferenceView()
    this.snapshot = tz.snapshot()
    this.datepickerSetting = {field: 'datepickerSetting', type: 'date_picker'}
    fakeENV.setup({conference_type_details: [{settings: [this.datepickerSetting]}]})
  },
  teardown() {
    this.view.$el.remove()
    fakeENV.teardown()
    tz.restore(this.snapshot)
  }
})

test('updateConferenceUserSettingDetailsForConference localizes values for datepicker settings', function() {
  tz.changeLocale(french, 'fr_FR', 'fr')
  I18nStubber.pushFrame()
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {'date.formats.full_with_weekday': '%a %-d %b, %Y %-k:%M'})

  const conferenceData = {user_settings: {datepickerSetting: '2015-08-07T17:00:00Z'}}
  this.view.updateConferenceUserSettingDetailsForConference(conferenceData)
  equal(this.datepickerSetting.value, 'ven. 7 août, 2015 17:00')
  I18nStubber.popFrame()
})

test('#show sets the proper title for new conferences', function() {
  const expectedTitle = 'New Conference'
  const attributes = {
    recordings: [],
    user_settings: {
      scheduled_date: new Date()
    },
    permissions: {
      update: true
    }
  }

  const conference = new Conference(attributes)
  this.view.show(conference)
  const title = this.view.$el.dialog('option', 'title')
  equal(title, expectedTitle)
})

test('#show sets the proper title for editing conferences', function() {
  const expectedTitle = 'Edit &quot;InstructureCon&quot;'
  const attributes = {
    title: 'InstructureCon',
    recordings: [],
    user_settings: {
      scheduled_date: new Date()
    },
    permissions: {
      update: true
    }
  }

  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})
  const title = this.view.$el.dialog('option', 'title')
  equal(title, expectedTitle)
})

test('#show sets localized durataion when editing conference', function() {
  const expectedDuration = '1,234.5'
  const attributes = {
    title: 'InstructureCon',
    recordings: [],
    user_settings: {
      scheduled_date: new Date()
    },
    permissions: {
      update: true
    },
    duration: 1234.5
  }

  const conference = new Conference(attributes)
  this.view.show(conference, {isEditing: true})
  const duration = this.view.$('#web_conference_duration')[0].value
  equal(duration, expectedDuration)
})
