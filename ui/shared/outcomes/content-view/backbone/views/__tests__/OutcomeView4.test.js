/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import 'jquery-migrate'
import I18nStubber from '@canvas/test-utils/I18nStubber'
import Outcome from '../../../../backbone/models/Outcome'
import OutcomeContentBase from '../OutcomeContentBase'
import OutcomeView from '../OutcomeView'

// stub function that creates the RCE to avoid
// its async initialization
OutcomeContentBase.prototype.readyForm = () => {}

const newOutcome = (outcomeOptions, outcomeLinkOptions) =>
  new Outcome(buildOutcome(outcomeOptions, outcomeLinkOptions), {parse: true})

const waitFrames = async frames => {
  for (let i = 0; i < frames; i++) {
    await new Promise(resolve => requestAnimationFrame(resolve))
  }
}

function buildOutcome(outcomeOptions, outcomeLinkOptions) {
  const base = {
    context_type: 'Course',
    context_id: 1,
    outcome_group: {outcomes_url: 'blah'},
    outcome: {
      id: 1,
      title: 'Outcome1',
      description: 'outcome1 test',
      context_type: 'Course',
      context_id: 1,
      points_possible: '5',
      mastery_points: '3',
      url: 'blah',
      calculation_method: 'decaying_average',
      calculation_int: 65,
      assessed: false,
      can_edit: true,
    },
  }
  if (outcomeOptions) {
    Object.assign(base.outcome, outcomeOptions)
  }
  if (outcomeLinkOptions) {
    Object.assign(base, outcomeLinkOptions)
  }
  return base
}

function createView(opts) {
  const application = $('<div id="application" />') // app element for confirmation dialog
  application.appendTo($('#fixtures'))

  const view = new OutcomeView(opts)
  view.$el.appendTo(application)
  return view.render()
}

describe('OutcomeView', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  describe('Form Validation', () => {
    it('validates mastery points', async () => {
      const view = createView({
        model: newOutcome(),
        state: 'edit',
      })
      await waitFrames(10)
      const input = view.$('#mastery_points')
      expect(input).toHaveLength(1)
      input.val('-1').trigger('change')
      expect(view.isValid()).toBeFalsy()
      expect(view.errors.mastery_points).toBeTruthy()
      view.remove()
    })

    it('validates i18n mastery points', async () => {
      const view = createView({
        model: newOutcome(),
        state: 'edit',
      })
      await waitFrames(10)
      I18nStubber.pushFrame()
      I18nStubber.setLocale('fr_FR')
      I18nStubber.stub('fr_FR', {
        'number.format.delimiter': ' ',
        'number.format.separator': ',',
      })
      await waitFrames(10)
      view.$('input[name="mastery_points"]').val('1 234,5')
      await waitFrames(10)
      expect(view.isValid()).toBeTruthy()
      view.remove()
      I18nStubber.clear()
    })
  })
})
