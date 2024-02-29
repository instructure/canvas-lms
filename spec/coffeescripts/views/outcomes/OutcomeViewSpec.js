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
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'

import OutcomeContentBase from '@canvas/outcomes/content-view/backbone/views/OutcomeContentBase'
import Outcome from '@canvas/outcomes/backbone/models/Outcome'
import OutcomeView from '@canvas/outcomes/content-view/backbone/views/OutcomeView'
import I18nStubber from 'helpers/I18nStubber'

// stub function that creates the RCE to avoid
// its async initializationa
OutcomeContentBase.prototype.readyForm = () => {}

const newOutcome = (outcomeOptions, outcomeLinkOptions) =>
  new Outcome(buildOutcome(outcomeOptions, outcomeLinkOptions), {parse: true})

const outcome1 = () => new Outcome(buildOutcome1(), {parse: true})

const buildOutcome1 = () =>
  buildOutcome({
    calculation_method: 'decaying_average',
    calculation_int: '65',
  })

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

function changeSelectedCalcMethod(view, calcMethod) {
  view.$('#calculation_method').val(calcMethod)
  return view.$('#calculation_method').trigger('change')
}

function commonTests() {
  test('outcome is created successfully', function () {
    ok(this.outcome1.get('context_id'), 'upper context id')
    ok(this.outcome1.outcomeLink)
    ok(this.outcome1.outcomeLink.context_id)
    ok(this.outcome1.outcomeLink.context_type)
    ok(this.outcome1.outcomeLink.outcome)
    ok(this.outcome1.outcomeLink.outcome.context_id)
    ok(this.outcome1.outcomeLink.outcome.context_type)
    ok(this.outcome1.outcomeLink.outcome.title)
    ok(this.outcome1.outcomeLink.outcome.id)
  })

  test('placeholder text is rendered properly for new outcomes', () => {
    const view = createView({
      model: newOutcome(),
      state: 'add',
    })
    equal(view.$('input[name="title"]').attr('placeholder'), 'New Outcome')
    view.remove()
  })

  test('delete buttons is disabled for outcomes that have been assessed', () => {
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
        }
      ),
      state: 'show',
    })
    ok(view.$('.delete_button').length > 0)
    ok(view.$('.delete_button').prop('disabled'))
    view.remove()
  })

  test('delete buttons is enabled for outcomes that have not been assessed', () => {
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
        }
      ),
      state: 'show',
    })
    ok(view.$('.delete_button').length > 0)
    notOk(view.$('.delete_button').prop('disabled'))
    view.remove()
  })

  test('edit is enabled when viewing an assessed account outcome in its native context', () => {
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
    ok(view.$('.edit_button').length > 0)
    notOk(view.$('.edit_button').prop('disabled'))
    view.remove()
  })

  test('delete button is not shown for outcomes that cannot be unlinked', () => {
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
        }
      ),
      state: 'show',
    })
    ok(view.$('.edit_button').length > 0)
    strictEqual(view.$('.delete_button').length, 0)
    view.remove()
  })

  test('move and delete buttons are available for an account outcome if a user is a local admin', () => {
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
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
        }
      ),
      state: 'show',
    })
    ok(view.$('.delete_button').length > 0)
    ok(view.$('.move_button').length > 0)
    strictEqual(view.$('.edit_button').length, 0)
    view.remove()
  })

  test('move and delete buttons are not available for an account outcome if a user is a teacher', () => {
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
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
        }
      ),
      state: 'show',
    })
    strictEqual(view.$('.delete_button').length, 0)
    strictEqual(view.$('.move_button').length, 0)
    strictEqual(view.$('.edit_button').length, 0)
    view.remove()
  })

  test('it attempts a confirmation dialog when an outcome is modified', assert => {
    const done = assert.async()
    const view = createView({
      model: newOutcome(
        {assessed: true, native: true, has_updateable_rubrics: true},
        {can_unlink: true}
      ),
      state: 'edit',
    })
    view.edit($.Event())
    view.$('#title').val('this is a brand new title')
    view.$('form').trigger('submit')
    setTimeout(() => {
      ok($('.confirm-outcome-edit-modal-container').length > 0)
      // cleanup
      $('#cancel-outcome-edit-modal').trigger('click')
      $('.confirm-outcome-edit-modal-container').remove()
      done()
    })
  })

  test('it saves without dialog when outcome is unchanged', assert => {
    const done = assert.async()
    const view = createView({
      model: newOutcome(
        {assessed: true, native: true, has_updateable_rubrics: true},
        {can_unlink: true}
      ),
      state: 'edit',
    })
    view.edit($.Event())
    view.$('form').trigger('submit')
    view.on('submit', () => {
      ok(true, 'submit fired on form view')
      done()
    })
    setTimeout(() => {
      $('#confirm-outcome-edit-modal').trigger('click')
    })
  })

  test('it saves without dialog when outcome title is changed but no rubrics aligned', assert => {
    const done = assert.async()
    const view = createView({
      model: newOutcome(
        {assessed: true, native: true, has_updateable_rubrics: false},
        {can_unlink: true}
      ),
      state: 'edit',
    })
    view.edit($.Event())
    view.$('form').trigger('submit')
    view.on('submit', () => {
      ok(true, 'submit fired on form view')
      done()
    })
    setTimeout(() => {
      $('#confirm-outcome-edit-modal').trigger('click')
    })
  })

  test('delete button is disabled for account outcomes that have been assessed in this course', () => {
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
        }
      ),
      state: 'show',
    })
    ok(view.$el.find('.delete_button').length > 0)
    ok(view.$el.find('.delete_button').prop('disabled'))
    view.remove()
  })

  test('delete button is enabled for account outcomes that have been assessed, but not in this course', () => {
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
        }
      ),
      state: 'show',
    })
    ok(view.$el.find('.delete_button').length > 0)
    ok(!view.$el.find('.delete_button').prop('disabled'))
    view.remove()
  })

  test('validates title is present', function () {
    const view = createView({
      model: this.outcome1,
      state: 'edit',
    })
    view.$('#title').val('')
    view.$('#dtitle').trigger('change')
    ok(!view.isValid())
    ok(view.errors.title)
    view.remove()
  })

  test('validates title length', function () {
    const long_name = 'X'.repeat(260)
    const view = createView({
      model: this.outcome1,
      state: 'edit',
    })
    view.$('#title').val(long_name)
    ok(!view.isValid())
    ok(view.errors.title)
    view.remove()
  })

  test('validates display_name length', function () {
    const long_name = 'X'.repeat(260)
    const view = createView({
      model: this.outcome1,
      state: 'edit',
    })
    view.$('#display_name').val(long_name)
    ok(!view.isValid())
    ok(view.errors.display_name)
    view.remove()
  })
}

QUnit.module('OutcomeView', {
  setup() {
    fakeENV.setup()
    // Sometimes TinyMCE has stuff on the dom that causes issues, likely from things that
    // don't clean up properly, we make sure that these run in a clean tiny state each time
    window.tinymce?.remove()
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.OUTCOME_AVERAGE_CALCULATION = true
    this.outcome1 = outcome1()
  },
  teardown() {
    fakeENV.teardown()
    window.tinymce?.remove() // Don't leave anything hanging around
    document.getElementById('fixtures').innerHTML = ''
  },
})

commonTests()

test('dropdown includes available calculation methods', function () {
  const view = createView({
    model: this.outcome1,
    state: 'edit',
  })
  const methods = $.map($('#calculation_method option'), option => option.value)
  deepEqual(['decaying_average', 'n_mastery', 'latest', 'highest', 'average'], methods)
  view.remove()
})

test('calculation method of decaying_average is rendered properly on show', function () {
  const view = createView({
    model: this.outcome1,
    state: 'show',
  })
  ok(view.$('#calculation_method').length)
  equal(view.$('#calculation_method').data('calculation-method'), 'decaying_average')
  equal(view.$('#calculation_int').text(), '65')
  ok(view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method of n mastery is rendered properly on show', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'n_mastery',
      calculation_int: 2,
    }),
    state: 'show',
  })
  equal(view.$('#calculation_method').data('calculation-method'), 'n_mastery')
  equal(view.$('#calculation_int').text(), '2')
  ok(
    view.$('#calculation_int_left_side').is(':visible'),
    'calculation_int_left_side should be visible'
  )
  view.remove()
})

test('calculation method of highest is rendered properly on show', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'highest',
      calculation_int: null,
    }),
    state: 'show',
  })
  equal(view.$('#calculation_method').data('calculation-method'), 'highest')
  ok(!view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method of latest is rendered properly on show', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'latest',
      calculation_int: null,
    }),
    state: 'show',
  })
  equal(view.$('#calculation_method').data('calculation-method'), 'latest')
  ok(!view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method of average is rendered properly on show', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'average',
      calculation_int: null,
    }),
    state: 'show',
  })
  equal(view.$('#calculation_method').data('calculation-method'), 'average')
  ok(!view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method of decaying_average is rendered properly on edit', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'decaying_average',
      calculation_int: 65,
    }),
    state: 'edit',
  })
  equal(view.$('#calculation_method').val(), 'decaying_average')
  equal(view.$('#calculation_int').val(), '65')
  ok(view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method of n mastery is rendered properly on edit', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'n_mastery',
      calculation_int: 2,
    }),
    state: 'edit',
  })
  equal(view.$('#calculation_method').val(), 'n_mastery')
  equal(view.$('#calculation_int').val(), '2')
  ok(view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method of highest is rendered properly on edit', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'highest',
      calculation_int: null,
    }),
    state: 'edit',
  })
  equal(view.$('#calculation_method').val(), 'highest')
  ok(!view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method of latest is rendered properly on edit', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'latest',
      calculation_int: null,
    }),
    state: 'edit',
  })
  equal(view.$('#calculation_method').val(), 'latest')
  ok(!view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method of average is rendered properly on edit', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'average',
      calculation_int: null,
    }),
    state: 'edit',
  })
  equal(view.$('#calculation_method').val(), 'average')
  ok(!view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation method is rendered properly on add', () => {
  const view = createView({
    model: newOutcome(),
    state: 'add',
  })
  equal(view.$('#calculation_method').val(), 'decaying_average')
  equal(view.$('#calculation_int').val(), '65')
  ok(view.$('#calculation_int_left_side').is(':visible'))
  view.remove()
})

test('calculation int updates when the calculation method is changed', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'decaying_average',
      calculation_int: 75,
    }),
    state: 'edit',
  })
  equal(view.$('#calculation_method').val(), 'decaying_average')
  equal(view.$('#calculation_int').val(), '75')
  ok(
    view
      .$('#calculation_int_example')
      .text()
      .match(/75\% of mastery weight/)
  )
  changeSelectedCalcMethod(view, 'n_mastery')
  equal(view.$('#calculation_method').val(), 'n_mastery')
  equal(view.$('#calculation_int').val(), '5')
  ok(
    view
      .$('#calculation_int_example')
      .text()
      .match(/achieve mastery at least 5 times/)
  )
  changeSelectedCalcMethod(view, 'highest')
  equal(view.$('#calculation_method').val(), 'highest')
  ok(
    view
      .$('#calculation_int_example')
      .text()
      .match(/highest score/)
  )
  changeSelectedCalcMethod(view, 'latest')
  equal(view.$('#calculation_method').val(), 'latest')
  ok(
    view
      .$('#calculation_int_example')
      .text()
      .match(/most recent/)
  )
  changeSelectedCalcMethod(view, 'average')
  equal(view.$('#calculation_method').val(), 'average')
  ok(
    view
      .$('#calculation_int_example')
      .text()
      .match(/value in a set/)
  )
  view.remove()
})

test('warning text present when viewing an assessed account outcome in its native context', () => {
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
  ok(view.$('.outcome-assessed-info-banner').length > 0)
  view.remove()
})

test('warning text is not present if outcome view is read-only', () => {
  const view = createView({model: newOutcome({assessed: true}, {}), readOnly: true})
  notOk(view.$('.outcome-assessed-info-banner').length > 0)
  view.remove()
})

test('an informative banner is displayed when outcome has been assessed', () => {
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
  ok(view.$('#assessed_info_banner').length > 0)
  view.remove()
})

test('the banner is not displayed when the outcome is not assessed', () => {
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
  ok(!view.$('#assessed_info_banner').length > 0)
})

test('it attempts a confirmation dialog when calculation is modified', assert => {
  const done = assert.async()
  const view = createView({
    model: newOutcome(
      {assessed: true, native: true, has_updateable_rubrics: true},
      {can_unlink: true}
    ),
    state: 'edit',
  })
  view.edit($.Event())
  changeSelectedCalcMethod(view, 'latest')
  view.$('form').trigger('submit')
  setTimeout(() => {
    ok($('.confirm-outcome-edit-modal-container').length > 0)
    // cleanup
    $('#cancel-outcome-edit-modal').trigger('click')
    $('.confirm-outcome-edit-modal-container').remove()
    done()
  })
})

test('validates mastery points', function () {
  const view = createView({
    model: this.outcome1,
    state: 'edit',
  })
  view.$('input[name="mastery_points"]').val('-1')
  ok(!view.isValid())
  ok(view.errors.mastery_points)
  view.remove()
})

test('validates i18n mastery points', function () {
  const view = createView({
    model: this.outcome1,
    state: 'edit',
  })
  I18nStubber.pushFrame()
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'number.format.delimiter': ' ',
    'number.format.separator': ',',
  })
  view.$('input[name="mastery_points"]').val('1 234,5')
  ok(view.isValid())
  view.remove()
  I18nStubber.clear()
})

test('getModifiedFields returns false for all fields when not modified', () => {
  const view = createView({model: newOutcome(), state: 'edit'})
  view.edit($.Event())
  const modified = view.getModifiedFields(view.getFormData())
  notOk(modified.masteryPoints)
  notOk(modified.calculationInt)
  notOk(modified.calculationMethod)
})

test('getModifiedFields returns true for calculation method when modified', () => {
  const view = createView({model: newOutcome(), state: 'edit'})
  view.edit($.Event())
  changeSelectedCalcMethod(view, 'latest')
  ok(view.getModifiedFields(view.getFormData()).scoringMethod)
})

test('getModifiedFields returns true for calculationInt when modified', () => {
  const view = createView({model: newOutcome(), state: 'edit'})
  view.edit($.Event())
  view.$('#calculation_int').val(2)
  view.$('#calculation_int').trigger('change')
  ok(view.getModifiedFields(view.getFormData()).scoringMethod)
})

test('getModifiedFields returns false when calculationInt changed but not used', () => {
  const view = createView({
    model: newOutcome({calculation_method: 'latest', calculation_int: null}),
    state: 'edit',
  })
  view.edit($.Event())
  changeSelectedCalcMethod(view, 'decaying_average')
  view.$('#calculation_int').val(33)
  view.$('#calculation_int').trigger('change')
  changeSelectedCalcMethod(view, 'latest')
  notOk(view.getModifiedFields(view.getFormData()).scoringMethod)
})

test('getModifiedFields returns true mastery points when modified', () => {
  const view = createView({model: newOutcome(), state: 'edit'})
  view.edit($.Event())
  view.$('.mastery_points').val(100)
  view.$('.mastery_points').trigger('keyup')
  ok(view.getModifiedFields(view.getFormData()).masteryPoints)
})

test('calculation int gets set intelligently when the calc method is changed', () => {
  const view = createView({
    model: newOutcome({calculation_method: 'highest'}),
    state: 'edit',
  })
  changeSelectedCalcMethod(view, 'n_mastery')
  equal(view.$('#calculation_int').val(), '5')
  changeSelectedCalcMethod(view, 'decaying_average')
  equal(view.$('#calculation_int').val(), '65')
  changeSelectedCalcMethod(view, 'n_mastery')
  equal(view.$('#calculation_int').val(), '5')
  view.$('#calculation_int').val('4')
  equal(view.$('#calculation_int').val(), '4')
  changeSelectedCalcMethod(view, 'decaying_average')
  equal(view.$('#calculation_int').val(), '65')
  changeSelectedCalcMethod(view, 'highest')
  changeSelectedCalcMethod(view, 'decaying_average')
  equal(view.$('#calculation_int').val(), '65')
  view.remove()
})

test('calc int is not incorrectly changed to 65 when starting as n mastery and 5', () => {
  const view = createView({
    model: newOutcome({
      calculation_method: 'n_mastery',
      calculation_int: 5,
    }),
    state: 'edit',
  })
  changeSelectedCalcMethod(view, 'n_mastery')
  equal(view.$('#calculation_int').val(), '5')
  view.remove()
})

test('it attempts a confirmation dialog when outcome calculation is modified', assert => {
  const done = assert.async()
  const view = createView({
    model: newOutcome(
      {assessed: true, native: true, has_updateable_rubrics: true},
      {can_unlink: true}
    ),
    state: 'edit',
  })
  view.edit($.Event())
  changeSelectedCalcMethod(view, 'latest')
  view.$('#title').val('this is a brand new title')
  view.$('form').trigger('submit')
  setTimeout(() => {
    ok($('.confirm-outcome-edit-modal-container').length > 0)
    // cleanup
    $('#cancel-outcome-edit-modal').trigger('click')
    $('.confirm-outcome-edit-modal-container').remove()
    done()
  })
})

test('it saves without dialog when outcome calculation is changed but no rubrics aligned and not assessed', assert => {
  const done = assert.async()
  const view = createView({
    model: newOutcome(
      {assessed: false, native: true, has_updateable_rubrics: false},
      {can_unlink: true}
    ),
    state: 'edit',
  })
  view.edit($.Event())
  view.$('form').trigger('submit')
  view.on('submit', () => {
    ok(true, 'submit fired on form view')
    done()
  })
  setTimeout(() => {
    $('#confirm-outcome-edit-modal').trigger('click')
  })
})

QUnit.module('OutcomeView with mastery scales', {
  setup() {
    fakeENV.setup()
    // Sometimes TinyMCE has stuff on the dom that causes issues, likely from things that
    // don't clean up properly, we make sure that these run in a clean tiny state each time
    window.tinymce?.remove()
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.ACCOUNT_LEVEL_MASTERY_SCALES = true
    this.outcome1 = outcome1()
  },
  teardown() {
    fakeENV.teardown()
    window.tinymce?.remove() // Don't leave anything hanging around
    document.getElementById('fixtures').innerHTML = ''
  },
})

commonTests()
