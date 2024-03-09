//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import startApp from '../start_app'
import Ember from 'ember'
import fixtures from '../ajax_fixtures'

let App = null
const ariaMuted = 'Click to unmute.'
const ariaUnmuted = 'Click to mute.'
const dialogTitleMuted = 'Unmute Assignment'
const dialogTitleUnmuted = 'Mute Assignment'

const sendSuccess = (server, url, state) =>
  server.respond('POST', url, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify({assignment: {muted: state}}),
  ])

const checkLabel = stateLabel =>
  equal(find('#assignment_muted_check').attr('aria-label'), stateLabel)

const checkChecked = expectedBool =>
  equal(find('#assignment_muted_check').prop('checked'), expectedBool)

function checkDialogClosed() {
  const dialog = find('.ui-dialog:visible', 'body')
  equal(dialog.length, 0, 'the dialog closes')
}

function closeDialog(dialog) {
  click(find('.ui-dialog-titlebar-close', dialog))
  return checkDialogClosed()
}

QUnit.module('screenreader_gradebook assignment_muter_component: muted', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(() => {
      this.con = App.__container__.lookup('controller:screenreader_gradebook')
      Ember.run(() =>
        this.con.set(
          'selectedAssignment',
          Ember.copy(fixtures.assignment_groups[0].assignments[1], true)
        )
      )
      return (this.server = sinon.fakeServer.create())
    })
  },
  teardown() {
    this.server.restore()
    return Ember.run(App, 'destroy')
  },
})

// unskip in FOO-4345
QUnit.skip('dialog cancels dialog without changes', () => {
  checkLabel(ariaMuted)
  checkChecked(true)
  return click('#assignment_muted_check').then(() => {
    const dialog = find('.ui-dialog:visible', 'body')
    click('[data-action="cancel"]', dialog)
    checkDialogClosed()
    checkChecked(true)
    return checkLabel(ariaMuted)
  })
})

// unskip in FOO-4345
QUnit.skip('dialog opens and closes without changes', () => {
  checkLabel(ariaMuted)
  checkChecked(true)
  return click('#assignment_muted_check').then(() => {
    const dialog = find('.ui-dialog:visible', 'body')
    equal(find('[data-action="unmute"]', dialog).text(), dialogTitleMuted)
    closeDialog(dialog)
    checkChecked(true)
    return checkLabel(ariaMuted)
  })
})

test('dialog opens and makes changes upon confirmation', function () {
  const {server} = this
  checkLabel(ariaMuted)
  checkChecked(true)
  return click('#assignment_muted_check').then(() => {
    let dialog = find('.ui-dialog:visible', 'body')
    click('[data-action="unmute"]', dialog)
    sendSuccess(
      server,
      `${ENV.GRADEBOOK_OPTIONS.context_url}/assignments/${this.con.get(
        'selectedAssignment.id'
      )}/mute`,
      false
    )
    return andThen(() => {
      dialog = find('.ui-dialog:visible', 'body')
      equal(dialog.length, 0, 'the dialog is closed')
      checkChecked(false)
      checkLabel(ariaUnmuted)
      equal(this.con.get('selectedAssignment.muted'), false)
      return server.restore()
    })
  })
})

QUnit.module('screenreader_gradebook assignment_muter_component: unmuted', {
  setup() {
    fixtures.create()
    App = startApp()
    return visit('/').then(() => {
      this.con = App.__container__.lookup('controller:screenreader_gradebook')
      Ember.run(() =>
        this.con.set(
          'selectedAssignment',
          Ember.copy(fixtures.assignment_groups[0].assignments[0], true)
        )
      )
      return (this.server = sinon.fakeServer.create())
    })
  },
  teardown() {
    this.server.restore()
    return Ember.run(App, 'destroy')
  },
})

// unskip in FOO-4345
QUnit.skip('dialog cancels dialog without changes', () => {
  checkLabel(ariaUnmuted)
  checkChecked(false)
  return click('#assignment_muted_check').then(() => {
    const dialog = find('.ui-dialog:visible', 'body')
    click('[data-action="cancel"]', dialog)
    checkDialogClosed()
    checkChecked(false)
    return checkLabel(ariaUnmuted)
  })
})

// unskip in FOO-4345
QUnit.skip('dialog opens and closes without changes', () => {
  checkLabel(ariaUnmuted)
  checkChecked(false)
  return click('#assignment_muted_check').then(() => {
    const dialog = find('.ui-dialog:visible', 'body')
    equal(find('[data-action="mute"]', dialog).text(), dialogTitleUnmuted)
    closeDialog(dialog)
    checkChecked(false)
    return checkLabel(ariaUnmuted)
  })
})

test('dialog opens and makes changes upon confirmation', function () {
  const {server} = this
  checkLabel(ariaUnmuted)
  checkChecked(false)
  return click('#assignment_muted_check').then(() => {
    let dialog = find('.ui-dialog:visible', 'body')
    click('[data-action="mute"]', dialog)
    sendSuccess(
      server,
      `${ENV.GRADEBOOK_OPTIONS.context_url}/assignments/${this.con.get(
        'selectedAssignment.id'
      )}/mute`,
      true
    )
    return andThen(() => {
      dialog = find('.ui-dialog:visible', 'body')
      equal(dialog.length, 0, 'the dialog is closed')
      checkChecked(true)
      checkLabel(ariaMuted)
      equal(this.con.get('selectedAssignment.muted'), true)
      return server.restore()
    })
  })
})
