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
import fakeENV from '@canvas/test-utils/fakeENV'
import Outcome from '../../../../backbone/models/Outcome'
import OutcomeContentBase from '../OutcomeContentBase'
import OutcomeView from '../OutcomeView'

// stub function that creates the RCE to avoid
// its async initialization
OutcomeContentBase.prototype.readyForm = () => {}

const newOutcome = (outcomeOptions, outcomeLinkOptions) =>
  new Outcome(buildOutcome(outcomeOptions, outcomeLinkOptions), {parse: true})

const outcome1 = () => new Outcome(buildOutcome1(), {parse: true})

const buildOutcome1 = () =>
  buildOutcome({
    calculation_method: 'decaying_average',
    calculation_int: '65',
  })

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
  let outcome1Instance

  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    outcome1Instance = outcome1()
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  describe('Basic Functionality', () => {
    it('creates outcome successfully', () => {
      expect(outcome1Instance.get('context_id')).toBeTruthy()
      expect(outcome1Instance.outcomeLink).toBeTruthy()
      expect(outcome1Instance.outcomeLink.context_id).toBeTruthy()
      expect(outcome1Instance.outcomeLink.context_type).toBeTruthy()
      expect(outcome1Instance.outcomeLink.outcome).toBeTruthy()
      expect(outcome1Instance.outcomeLink.outcome.context_id).toBeTruthy()
      expect(outcome1Instance.outcomeLink.outcome.context_type).toBeTruthy()
      expect(outcome1Instance.outcomeLink.outcome.title).toBeTruthy()
      expect(outcome1Instance.outcomeLink.outcome.id).toBeTruthy()
    })

    it('renders placeholder text properly for new outcomes', async () => {
      const view = createView({
        model: newOutcome(),
        state: 'add',
      })
      await waitFrames(10)
      expect(view.$('input[name="title"]').attr('placeholder')).toBe('New Outcome')
      // Description placeholder is not currently implemented in the template
    })
  })

  describe('Calculation Methods', () => {
    beforeEach(() => {
      fakeENV.setup({
        ACCOUNT_LEVEL_MASTERY_SCALES: false,
        CONTEXT_URL_ROOT: '/courses/1',
        OUTCOMES: {
          outcome_calculation_method: {
            decaying_average: {
              example: [
                {name: 'First Score', calculation: 85},
                {name: 'Second Score', calculation: 85},
                {name: 'Most Recent Score', calculation: 85},
              ],
              friendlyCalculationMethod: 'Decaying Average',
            },
            n_mastery: {
              example: [
                {name: 'Item 1', calculation: 1},
                {name: 'Item 2', calculation: 0},
                {name: 'Item 3', calculation: 1},
                {name: 'Item 4', calculation: 1},
              ],
              friendlyCalculationMethod: 'n Number of Times',
            },
            latest: {
              example: [
                {name: 'Item 1', calculation: 0},
                {name: 'Item 2', calculation: 1},
                {name: 'Item 3', calculation: 0},
                {name: 'Item 4', calculation: 1},
              ],
              friendlyCalculationMethod: 'Most Recent Score',
            },
            highest: {
              example: [
                {name: 'Item 1', calculation: 0},
                {name: 'Item 2', calculation: 1},
                {name: 'Item 3', calculation: 0},
                {name: 'Item 4', calculation: 1},
              ],
              friendlyCalculationMethod: 'Highest Score',
            },
          },
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('includes available calculation methods', () => {
      const view = createView({
        model: outcome1Instance,
        state: 'edit',
      })

      const $calcMethods = view.$('#calculation_method option')
      expect($calcMethods).toHaveLength(5) // Includes default empty option
      expect($calcMethods.eq(0).val()).toBe('decaying_average')
      expect($calcMethods.eq(1).val()).toBe('n_mastery')
      expect($calcMethods.eq(2).val()).toBe('latest')
      expect($calcMethods.eq(3).val()).toBe('highest')
      expect($calcMethods.eq(4).val()).toBe('average') // Last option is 'average'
    })

    it('updates calculation int when calculation method is changed', async () => {
      const model = newOutcome({
        calculation_method: 'decaying_average',
        calculation_int: 65,
      })
      const view = createView({
        model,
        state: 'edit',
      })

      model.set('calculation_method', 'n_mastery')
      await waitFrames(10)
      expect(view.$('#calculation_int').val()).toBe('5')

      model.set('calculation_method', 'highest')
      await waitFrames(10)
      expect(view.$('#calculation_int').val()).toBe('')

      model.set('calculation_method', 'decaying_average')
      await waitFrames(10)
      expect(view.$('#calculation_int').val()).toBe('65')
    })
  })
})
