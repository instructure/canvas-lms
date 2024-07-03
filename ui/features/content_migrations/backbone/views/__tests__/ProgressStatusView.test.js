/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import ProgressStatusView from '../ProgressStatusView'
import ProgressingModel from '../../models/ProgressingContentMigration'
import {isAccessible} from '@canvas/test-utils/jestAssertions'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toBe(y)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

let progressingModel
let psv
let $fixtures

describe('ProgressStatusViewSpec', () => {
  beforeEach(() => {
    progressingModel = new ProgressingModel()
    psv = new ProgressStatusView({model: progressingModel})
    $fixtures = $('#fixtures')
  })

  afterEach(() => {
    psv.remove()
  })

  test('it should be accessible', function (done) {
    isAccessible($fixtures, done, {a11yReport: true})
  })

  test('displays progress workflow_state when migrations workflow_state is running', function () {
    progressingModel.set('workflow_state', 'running') // this is a migration
    progressingModel.progressModel.set('workflow_state', 'foo')
    $fixtures.append(psv.render().el)
    equal(psv.$el.find('.label').text(), 'Foo', 'Displays correct workflow state')
  })

  test('displays migration workflow_state when migrations workflow_state is not running', function () {
    progressingModel.set('workflow_state', 'some_not_running_state')
    $fixtures.append(psv.render().el)
    equal(
      psv.$el.find('.label').text(),
      'Some not running state',
      'Displays correct workflow state'
    )
  })

  test('adds label-success class to status when status is complete', function () {
    progressingModel.set('workflow_state', 'complete')
    $fixtures.append(psv.render().el)
    ok(psv.$el.find('.label-success'), 'Adds the label-success class')
  })

  test('adds label-important class to status when status is failed', function () {
    progressingModel.set('workflow_state', 'failed')
    $fixtures.append(psv.render().el)
    ok(psv.$el.find('.label-important'), 'Adds the label-important class')
  })

  test('adds label-info class to status when status is running', function () {
    progressingModel.set('workflow_state', 'running')
    progressingModel.progressModel.set('workflow_state', 'running')
    $fixtures.append(psv.render().el)
    ok(psv.$el.find('.label-info'), 'Adds the label-info class')
  })
})
