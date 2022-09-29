/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import ReuploadSubmissionsDialogManager from 'ui/features/gradebook/react/shared/ReuploadSubmissionsDialogManager'

QUnit.module('ReuploadSubmissionsDialogManager#constructor')

test('constructs reupload url from given assignment data and url template', () => {
  const manager = new ReuploadSubmissionsDialogManager(
    {
      id: 'the_id',
    },
    'the_{{ assignment_id }}_url',
    'user_22',
    {}
  )

  strictEqual(manager.reuploadUrl, 'the_the_id_url')
})

QUnit.module('ReuploadSubmissionsDialogManager#isDialogEnabled')

test('returns true when assignment submssions have been downloaded', () => {
  const manager = new ReuploadSubmissionsDialogManager({id: '123'}, 'the_url', 'user_22', {
    123: true,
  })

  strictEqual(manager.isDialogEnabled(), true)
})

test('returns false when assignment submssions have not been downloaded', () => {
  const manager = new ReuploadSubmissionsDialogManager({id: '123'}, 'the_url', 'user_22', {
    123: false,
  })

  strictEqual(manager.isDialogEnabled(), false)
})

QUnit.module('ReuploadSubmissionsDialogManager#showDialog')

test('sets form action to reupload url', () => {
  const manager = new ReuploadSubmissionsDialogManager(
    {
      id: 'the_id',
    },
    'the_{{ assignment_id }}_url',
    'user_22',
    {}
  )
  const dialog = sinon.stub()
  const attr = sinon.stub().returns({dialog})
  sandbox.stub(manager, 'getReuploadForm').returns({attr})
  manager.showDialog()

  ok(attr.calledWith('action', 'the_the_id_url'))
})

test('opens dialog', () => {
  const manager = new ReuploadSubmissionsDialogManager(
    {
      id: 'the_id',
    },
    'the_{{ assignment_id }}_url',
    'user_22',
    {}
  )
  const dialog = sinon.stub()
  const attr = sinon.stub().returns({dialog})
  sandbox.stub(manager, 'getReuploadForm').returns({attr})
  manager.showDialog()

  strictEqual(dialog.callCount, 1)
})
