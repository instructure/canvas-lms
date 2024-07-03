/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {isUndefined} from 'lodash'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomePopoverView from '../OutcomePopoverView'
import OutcomeDialogView from '../OutcomeDialogView'
import OutcomeView from '../OutcomeView'
import ProgressBarView from '../ProgressBarView'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

const ok = x => expect(x).toBeTruthy()

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

let outcomeView
let e

describe('OutcomeViewSpec', () => {
  beforeEach(() => {
    outcomeView = new OutcomeView({
      el: $('<li><a class="more-details"></a></li>'),
      model: new Outcome(),
    })
    e = function (name, options = {}) {
      return $.Event(name, {...options, currentTarget: outcomeView.$el.find('a.more-details')})
    }
  })

  test('should be accessible', function (done) {
    isAccessible(outcomeView, done, {a11yReport: true})
  })

  test('assign instance of ProgressBarView on init', function () {
    ok(outcomeView.progress instanceof ProgressBarView)
  })

  test('have after render behavior', function () {
    ok(isUndefined(outcomeView.popover), 'precondition')
    outcomeView.render()
    ok(outcomeView.popover instanceof OutcomePopoverView)
    ok(outcomeView.dialog instanceof OutcomeDialogView)
  })

  test('click & keydown .more-details', function () {
    outcomeView.render()
    const showSpy = sandbox.stub(outcomeView.dialog, 'show')
    outcomeView.$el.find('a.more-details').trigger(e('click'))
    ok(showSpy.called)
    showSpy.reset()
    outcomeView.$el.find('a.more-details').trigger(e('keydown'))
    ok(showSpy.called)
  })
})
