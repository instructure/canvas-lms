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
          }
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
          }
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
          {can_unlink: true}
        ),
        state: 'show',
      })
      expect(view.$('#assessed_info_banner')).toHaveLength(0)
    })
  })

  describe('Form Validation', () => {
    it('validates mastery points', () => {
      const view = createView({
        model: newOutcome(),
        state: 'edit',
      })
      view.$('input[name="mastery_points"]').val('-1')
      expect(view.isValid()).toBeFalsy()
      expect(view.errors.mastery_points).toBeTruthy()
      view.remove()
    })

    it('validates i18n mastery points', () => {
      const view = createView({
        model: newOutcome(),
        state: 'edit',
      })
      I18nStubber.pushFrame()
      I18nStubber.setLocale('fr_FR')
      I18nStubber.stub('fr_FR', {
        'number.format.delimiter': ' ',
        'number.format.separator': ',',
      })
      view.$('input[name="mastery_points"]').val('1 234,5')
      expect(view.isValid()).toBeTruthy()
      view.remove()
      I18nStubber.clear()
    })
  })

  describe('Form Field Modifications', () => {
    it('returns false for all fields when not modified', () => {
      const view = createView({model: newOutcome(), state: 'edit'})
      view.edit($.Event())
      const modified = view.getModifiedFields(view.getFormData())
      expect(modified.masteryPoints).toBeFalsy()
      expect(modified.calculationInt).toBeFalsy()
      expect(modified.calculationMethod).toBeFalsy()
    })

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
    it('sets calculation int intelligently when calc method is changed', () => {
      const view = createView({
        model: newOutcome({calculation_method: 'highest'}),
        state: 'edit',
      })
      view.$('#calculation_method').val('n_mastery').trigger('change')
      expect(view.$('#calculation_int').val()).toBe('5')
      
      view.$('#calculation_method').val('decaying_average').trigger('change')
      expect(view.$('#calculation_int').val()).toBe('65')
      
      view.$('#calculation_method').val('n_mastery').trigger('change')
      expect(view.$('#calculation_int').val()).toBe('5')
      
      view.$('#calculation_int').val('4')
      expect(view.$('#calculation_int').val()).toBe('4')
      
      view.$('#calculation_method').val('decaying_average').trigger('change')
      expect(view.$('#calculation_int').val()).toBe('65')
      
      view.$('#calculation_method').val('highest').trigger('change')
      view.$('#calculation_method').val('decaying_average').trigger('change')
      expect(view.$('#calculation_int').val()).toBe('65')
      view.remove()
    })

    it('does not change calc int to 65 when starting as n mastery and 5', () => {
      const view = createView({
        model: newOutcome({
          calculation_method: 'n_mastery',
          calculation_int: 5,
        }),
        state: 'edit',
      })
      view.$('#calculation_method').val('n_mastery').trigger('change')
      expect(view.$('#calculation_int').val()).toBe('5')
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
          {can_unlink: true}
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

    it('saves without dialog when outcome calculation is changed but no rubrics aligned and not assessed', () => {
      const view = createView({
        model: newOutcome(
          {assessed: false, native: true, has_updateable_rubrics: false},
          {can_unlink: true}
        ),
        state: 'edit',
      })
      view.edit($.Event())
      const submitSpy = jest.fn()
      view.on('submit', submitSpy)
      view.$('form').trigger('submit')

      return new Promise(resolve => {
        setTimeout(() => {
          $('#confirm-outcome-edit-modal').trigger('click')
          expect(submitSpy).toHaveBeenCalled()
          resolve()
        })
      })
    })
  })
})
