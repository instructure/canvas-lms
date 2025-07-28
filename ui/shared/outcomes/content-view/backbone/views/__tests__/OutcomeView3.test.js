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

const waitFrames = async frames => {
  for (let i = 0; i < frames; i++) {
    await new Promise(resolve => requestAnimationFrame(resolve))
  }
}

describe('OutcomeView', () => {
  let outcome1

  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    outcome1 = new Outcome(buildOutcome(), {parse: true})
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  describe('Delete Button Behavior', () => {
    it('is disabled for outcomes that have been assessed', () => {
      const view = createView({
        model: newOutcome(
          {
            assessed: true,
            native: true,
            can_edit: true,
            can_unlink: true,
          },
          {
            assessed: true,
            can_unlink: true,
          },
        ),
        state: 'show',
      })
      expect(view.$('.delete_button').length).toBeGreaterThan(0)
      expect(view.$('.delete_button').prop('disabled')).toBeTruthy()
      view.remove()
    })

    it('is enabled for outcomes that have not been assessed', () => {
      const view = createView({
        model: newOutcome(
          {
            assessed: false,
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
      expect(view.$('.delete_button').length).toBeGreaterThan(0)
      expect(view.$('.delete_button').prop('disabled')).toBeFalsy()
      view.remove()
    })

    it('is not shown for outcomes that cannot be unlinked', () => {
      const view = createView({
        model: newOutcome(
          {
            assessed: false,
            native: true,
            can_edit: true,
            can_unlink: true,
          },
          {
            assessed: false,
            can_unlink: false,
          },
        ),
        state: 'show',
      })
      expect(view.$('.edit_button').length).toBeGreaterThan(0)
      expect(view.$('.delete_button')).toHaveLength(0)
      view.remove()
    })

    it('is disabled for account outcomes assessed in this course', () => {
      const view = createView({
        model: newOutcome(
          {
            assessed: true,
            native: false,
            can_edit: true,
            context_type: 'Account',
          },
          {
            assessed: true,
            can_unlink: true,
          },
        ),
        state: 'show',
      })
      expect(view.$el.find('.delete_button').length).toBeGreaterThan(0)
      expect(view.$el.find('.delete_button').prop('disabled')).toBeTruthy()
      view.remove()
    })

    it('is enabled for account outcomes assessed but not in this course', () => {
      const view = createView({
        model: newOutcome(
          {
            assessed: true,
            native: false,
            can_edit: true,
            context_type: 'Account',
          },
          {
            assessed: false,
            can_unlink: true,
          },
        ),
        state: 'show',
      })
      expect(view.$el.find('.delete_button').length).toBeGreaterThan(0)
      expect(view.$el.find('.delete_button').prop('disabled')).toBeFalsy()
      view.remove()
    })
  })

  describe('Edit Button Behavior', () => {
    it('is enabled when viewing an assessed account outcome in its native context', () => {
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
      expect(view.$('.edit_button').length).toBeGreaterThan(0)
      expect(view.$('.edit_button').prop('disabled')).toBeFalsy()
      view.remove()
    })
  })

  describe('Move Button Behavior', () => {
    beforeEach(() => {
      ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
      ENV.PERMISSIONS = {manage_outcomes: true}
    })

    it('is available for an account outcome if user is a local admin', () => {
      ENV.current_user_is_admin = true
      const view = createView({
        model: newOutcome(
          {
            context_type: 'Account',
            assessed: false,
            native: false,
            can_edit: false,
            can_unlink: true,
          },
          {
            assessed: false,
            can_unlink: true,
          },
        ),
        state: 'show',
      })
      expect(view.$('.delete_button').length).toBeGreaterThan(0)
      expect(view.$('.move_button').length).toBeGreaterThan(0)
      expect(view.$('.edit_button')).toHaveLength(0)
      view.remove()
    })

    it('is not available for an account outcome if user is a teacher', () => {
      ENV.current_user_roles = ['teacher']
      ENV.current_user_is_admin = false
      const view = createView({
        model: newOutcome(
          {
            context_type: 'Account',
            assessed: false,
            native: false,
            can_edit: false,
            can_unlink: true,
          },
          {
            assessed: false,
            can_unlink: true,
          },
        ),
        state: 'show',
      })
      expect(view.$('.delete_button')).toHaveLength(0)
      expect(view.$('.move_button')).toHaveLength(0)
      expect(view.$('.edit_button')).toHaveLength(0)
      view.remove()
    })
  })

  describe('Form Validation', () => {
    it('validates title is present', async () => {
      const view = createView({
        model: outcome1,
        state: 'edit',
      })
      await waitFrames(10)
      view.$('#title').val('')
      view.$('#dtitle').trigger('change')
      await waitFrames(10)
      expect(view.isValid()).toBeFalsy()
      expect(view.errors.title).toBeTruthy()
      view.remove()
    })

    it('validates title length', async () => {
      const long_name = 'X'.repeat(260)
      const view = createView({
        model: outcome1,
        state: 'edit',
      })
      await waitFrames(10)
      view.$('#title').val(long_name)
      expect(view.isValid()).toBeFalsy()
      expect(view.errors.title).toBeTruthy()
      view.remove()
    })

    it('validates display_name length', async () => {
      const long_name = 'X'.repeat(260)
      const view = createView({
        model: outcome1,
        state: 'edit',
      })
      await waitFrames(10)
      view.$('#display_name').val(long_name)
      await waitFrames(10)
      expect(view.isValid()).toBeFalsy()
      expect(view.errors.display_name).toBeTruthy()
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

    it('shows dialog when outcome is modified', async () => {
      const view = createView({
        model: newOutcome(
          {assessed: true, native: true, has_updateable_rubrics: true},
          {can_unlink: true},
        ),
        state: 'edit',
      })
      await waitFrames(10)
      view.edit($.Event())
      await waitFrames(10)
      view.$('#title').val('this is a brand new title')
      view.$('form').trigger('submit')
      await waitFrames(10)
      
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

    it('saves without dialog when outcome is unchanged', async () => {
      const view = createView({
        model: newOutcome(
          {assessed: true, native: true, has_updateable_rubrics: true},
          {can_unlink: true},
        ),
        state: 'edit',
      })
      await waitFrames(10)
      view.edit($.Event())
      await waitFrames(10)
      const submitSpy = jest.fn()
      view.on('submit', submitSpy)
      view.$('form').trigger('submit')
      await waitFrames(10)
      
      return new Promise(resolve => {
        setTimeout(async () => {
          $('#confirm-outcome-edit-modal').trigger('click')
          await waitFrames(10)
          expect(submitSpy).toHaveBeenCalled()
          resolve()
        })
      })
    })

    it('saves without dialog when outcome title is changed but no rubrics aligned', async () => {
      const view = createView({
        model: newOutcome(
          {assessed: true, native: true, has_updateable_rubrics: false},
          {can_unlink: true},
        ),
        state: 'edit',
      })
      await waitFrames(10)
      view.edit($.Event())
      await waitFrames(10)
      const submitSpy = jest.fn()
      view.on('submit', submitSpy)
      view.$('form').trigger('submit')
      await waitFrames(10)
      
      return new Promise(resolve => {
        setTimeout(async () => {
          $('#confirm-outcome-edit-modal').trigger('click')
          await waitFrames(10)
          expect(submitSpy).toHaveBeenCalled()
          resolve()
        })
      })
    })
  })

  describe('With Mastery Scales', () => {
    beforeEach(() => {
      fakeENV.setup()
      window.tinymce?.remove()
      ENV.PERMISSIONS = {manage_outcomes: true}
      ENV.ACCOUNT_LEVEL_MASTERY_SCALES = true
    })

    afterEach(() => {
      fakeENV.teardown()
      window.tinymce?.remove()
      document.getElementById('fixtures').innerHTML = ''
    })

    it('creates outcome successfully', () => {
      const outcome = newOutcome()
      expect(outcome.get('context_id')).toBeTruthy()
      expect(outcome.outcomeLink).toBeTruthy()
      expect(outcome.outcomeLink.context_id).toBeTruthy()
      expect(outcome.outcomeLink.context_type).toBeTruthy()
      expect(outcome.outcomeLink.outcome).toBeTruthy()
      expect(outcome.outcomeLink.outcome.context_id).toBeTruthy()
      expect(outcome.outcomeLink.outcome.context_type).toBeTruthy()
      expect(outcome.outcomeLink.outcome.title).toBeTruthy()
      expect(outcome.outcomeLink.outcome.id).toBeTruthy()
    })

    it('renders placeholder text properly for new outcomes', async () => {
      const view = createView({
        model: newOutcome(),
        state: 'add',
      })
      await waitFrames(10)
      expect(view.$('input[name="title"]').attr('placeholder')).toBe('New Outcome')
      view.remove()
    })
  })
})
