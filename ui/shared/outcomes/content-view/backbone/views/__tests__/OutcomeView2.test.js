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
    fakeENV.setup()
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('body').attr('class', '')
    $('.ui-dialog').remove()
  })

  afterEach(() => {
    $('.ui-dialog').remove()
    $('.ui-widget-overlay').remove()
    document.body.innerHTML = ''
    $('body').attr('class', '')
    fakeENV.teardown()
  })

  describe('Assessment Banners', () => {
    it('shows warning text when viewing an assessed account outcome in its native context', () => {
      const view = createView({
        model: newOutcome(
          {
            assessed: true,
            native: true,
            can_edit: true,
            can_unlink: true,
          },
          {
            assessed: false,
            can_unlink: true,
          },
        ),
        state: 'show',
      })
      expect(view.$('.outcome-assessed-info-banner').length).toBeGreaterThan(0)
      view.remove()
    })

    it('does not show warning text if outcome view is read-only', () => {
      const view = createView({model: newOutcome({assessed: true}, {}), readOnly: true})
      expect(view.$('.outcome-assessed-info-banner')).toHaveLength(0)
      view.remove()
    })

    it('displays informative banner when outcome has been assessed', () => {
      const view = createView({
        model: newOutcome(
          {
            assessed: true,
            native: true,
          },
          {
            assessed: true,
            can_unlink: true,
          },
        ),
        state: 'show',
      })
      expect(view.$('#assessed_info_banner').length).toBeGreaterThan(0)
      view.remove()
    })

    it('does not display banner when outcome is not assessed', () => {
      const view = createView({
        model: newOutcome(
          {
            assessed: false,
            native: true,
          },
          {can_unlink: true},
        ),
        state: 'show',
      })
      expect(view.$('#assessed_info_banner')).toHaveLength(0)
    })
  })

  describe('Form Field Modifications', () => {
    it('returns true for calculation method when modified', () => {
      const view = createView({model: newOutcome(), state: 'edit'})
      view.edit($.Event())
      view.$('#calculation_method').val('latest').trigger('change')
      expect(view.getModifiedFields(view.getFormData()).scoringMethod).toBeTruthy()
    })

    it('returns true for calculationInt when modified', () => {
      const view = createView({model: newOutcome(), state: 'edit'})
      view.edit($.Event())
      view.$('#calculation_int').val(2).trigger('change')
      expect(view.getModifiedFields(view.getFormData()).scoringMethod).toBeTruthy()
    })

    it('returns false when calculationInt changed but not used', () => {
      const view = createView({
        model: newOutcome({calculation_method: 'latest', calculation_int: null}),
        state: 'edit',
      })
      view.edit($.Event())
      view.$('#calculation_method').val('decaying_average').trigger('change')
      view.$('#calculation_int').val(33).trigger('change')
      view.$('#calculation_method').val('latest').trigger('change')
      expect(view.getModifiedFields(view.getFormData()).scoringMethod).toBeFalsy()
    })

    it('returns true for mastery points when modified', () => {
      const view = createView({model: newOutcome(), state: 'edit'})
      view.edit($.Event())
      view.$('.mastery_points').val(100).trigger('keyup')
      expect(view.getModifiedFields(view.getFormData()).masteryPoints).toBeTruthy()
    })
  })

  describe('Calculation Method Changes', () => {
    it('sets calculation int intelligently when calc method is changed', async () => {
      const view = createView({
        model: newOutcome({calculation_method: 'highest'}),
        state: 'edit',
      })

      view.edit($.Event())
      await waitFrames(30)

      expect(view.$('#calculation_method')).toHaveLength(1)

      view.$('#calculation_method').val('n_mastery').trigger('change')
      await waitFrames(30)

      const calcIntField = view.$('#calculation_int')
      expect(calcIntField).toHaveLength(1)

      await new Promise(resolve => setTimeout(resolve, 50))

      const calcIntValue = calcIntField.val()
      expect(calcIntValue).toBeDefined()
      expect(calcIntValue).toBe('5')

      view.$('#calculation_method').val('decaying_average').trigger('change')
      await waitFrames(30)
      await new Promise(resolve => setTimeout(resolve, 50))
      expect(view.$('#calculation_int').val()).toBe('65')

      view.$('#calculation_method').val('n_mastery').trigger('change')
      await waitFrames(30)
      await new Promise(resolve => setTimeout(resolve, 50))
      expect(view.$('#calculation_int').val()).toBe('5')

      view.$('#calculation_int').val('4').trigger('change')
      await waitFrames(30)
      expect(view.$('#calculation_int').val()).toBe('4')

      view.$('#calculation_method').val('decaying_average').trigger('change')
      await waitFrames(30)
      await new Promise(resolve => setTimeout(resolve, 50))
      expect(view.$('#calculation_int').val()).toBe('65')

      view.$('#calculation_method').val('highest').trigger('change')
      await waitFrames(30)
      view.$('#calculation_method').val('decaying_average').trigger('change')
      await waitFrames(30)
      await new Promise(resolve => setTimeout(resolve, 50))
      expect(view.$('#calculation_int').val()).toBe('65')
      view.remove()
    })

    it('does not change calc int to 65 when starting as n mastery and 5', async () => {
      const view = createView({
        model: newOutcome({
          calculation_method: 'n_mastery',
          calculation_int: 5,
        }),
        state: 'edit',
      })

      view.edit($.Event())
      await waitFrames(30)

      view.$('#calculation_method').val('n_mastery').trigger('change')
      await waitFrames(30)
      await new Promise(resolve => setTimeout(resolve, 50))

      const calcIntValue = view.$('#calculation_int').val()
      expect(calcIntValue).toBeDefined()
      expect(calcIntValue).toBe('5')
      view.remove()
    })
  })

  describe('Confirmation Dialog', () => {
    beforeEach(() => {
      jest.spyOn(console, 'warn').mockImplementation(() => {})
    })

    afterEach(() => {
      console.warn.mockRestore()
    })

    it('shows confirmation dialog when outcome calculation is modified', () => {
      const view = createView({
        model: newOutcome(
          {assessed: true, native: true, has_updateable_rubrics: true},
          {can_unlink: true},
        ),
        state: 'edit',
      })
      view.edit($.Event())
      view.$('#calculation_method').val('latest').trigger('change')
      view.$('#title').val('this is a brand new title')
      view.$('form').trigger('submit')

      return new Promise(resolve => {
        setTimeout(() => {
          expect($('.confirm-outcome-edit-modal-container').length).toBeGreaterThan(0)
          // cleanup
          $('#cancel-outcome-edit-modal').trigger('click')
          $('.confirm-outcome-edit-modal-container').remove()
          resolve()
        })
      })
    })

    it('saves without dialog when outcome calculation is changed but no rubrics aligned and not assessed', async () => {
      const view = createView({
        model: newOutcome(
          {assessed: false, native: true, has_updateable_rubrics: false},
          {can_unlink: true},
        ),
        state: 'edit',
      })
      await waitFrames(10)
      view.edit($.Event())
      await waitFrames(10)

      view.$('#calculation_method').val('latest').trigger('change')
      await waitFrames(10)

      const submitSpy = jest.fn()
      view.on('submit', submitSpy)
      view.$('form').trigger('submit')

      return new Promise(resolve => {
        setTimeout(async () => {
          expect(submitSpy).toHaveBeenCalled()
          resolve()
        }, 100)
      })
    })
  })
})
