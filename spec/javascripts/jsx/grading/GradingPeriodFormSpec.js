/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import $ from 'jquery'
import {mount} from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'
import GradingPeriodForm from 'jsx/grading/GradingPeriodForm'
import chicago from 'timezone/America/Chicago'
import tz from 'timezone'
import fakeENV from 'helpers/fakeENV'

QUnit.module('GradingPeriodForm', suiteHooks => {
  let gradingPeriod
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    fakeENV.setup({CONTEXT_TIMEZONE: 'Etc/GMT+0', TIMEZONE: 'Etc/GMT+0'})

    gradingPeriod = {
      closeDate: new Date('2016-01-07T12:00:00Z'),
      endDate: new Date('2015-12-31T12:00:00Z'),
      id: '1401',
      startDate: new Date('2015-11-01T12:00:00Z'),
      title: 'Q1',
      weight: 30
    }

    props = {
      disabled: false,
      onCancel: sinon.spy(),
      onSave: sinon.spy(),
      period: gradingPeriod,
      weighted: true
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $('#ui-datepicker-div').datepicker('destroy')
    $('#ui-datepicker-div').remove()
    fakeENV.teardown()
  })

  function mountComponent() {
    wrapper = mount(<GradingPeriodForm {...props} />)
  }

  function getButton(label) {
    const buttons = wrapper.find('button')
    return buttons.filterWhere(button => button.text() === label)
  }

  function getDateInput(inputLabel) {
    const labels = wrapper.find('label')
    const $label = labels.filterWhere(label => label.text() === inputLabel).get(0)
    return wrapper.find(`input[aria-labelledby="${$label.id}"]`).get(0)
  }

  function getDateTimeSuggestions(inputLabel) {
    const $input = getDateInput(inputLabel)
    let $parent = $input.parentElement
    while ($parent && !$parent.classList.contains('ic-Form-control')) {
      $parent = $parent.parentElement
    }
    return Array.from($parent.querySelectorAll('.datetime_suggest'))
  }

  function getInput(id) {
    return wrapper.find(`input#${id}`).get(0)
  }

  function setDateInputValue(label, value) {
    const $input = getDateInput(label)
    $input.value = value
    $input.dispatchEvent(new Event('change', {target: $input}))
  }

  function setInputValue(id, value) {
    // Using Enzyme here is a workaround for React 14 swallowing input events.
    const input = wrapper.find(`input#${id}`)
    input.get(0).value = value
    input.simulate('change', {target: {value}})
  }

  QUnit.module('"Title" input', () => {
    test('value is set to the grading period title for an existing grading period', () => {
      mountComponent()
      equal(getInput('title').value, 'Q1')
    })
  })

  QUnit.module('"Start Date" input', () => {
    test('value is set to the grading period start date', () => {
      mountComponent()
      equal(getDateInput('Start Date').value, 'Nov 1, 2015 12pm')
    })

    QUnit.module('when local and server time are different', hooks => {
      hooks.beforeEach(() => {
        Object.assign(ENV, {CONTEXT_TIMEZONE: 'America/Chicago'})
        tz.preload('America/Chicago', chicago)
        mountComponent()
      })

      test('shows both local and context time suggestions for start date', () => {
        strictEqual(getDateTimeSuggestions('Start Date').length, 2)
      })

      test('formats the start date for the local timezone', () => {
        const $suggestions = getDateTimeSuggestions('Start Date')
        // Local is GMT
        strictEqual($suggestions[0].textContent, 'Local: Sun Nov 1, 2015 12:00pm')
      })

      test('formats the start date for the context timezone', () => {
        const $suggestions = getDateTimeSuggestions('Start Date')
        // Course is in Chicago
        strictEqual($suggestions[1].textContent, 'Account: Sun Nov 1, 2015 6:00am')
      })
    })

    test('does not show local and server time for start date when they are the same', () => {
      mountComponent()
      strictEqual(getDateTimeSuggestions('Start Date').length, 0)
    })
  })

  QUnit.module('"End Date" input', () => {
    test('value is set to the grading period end date', () => {
      mountComponent()
      equal(getDateInput('End Date').value, 'Dec 31, 2015 12pm')
    })

    /* eslint-disable-next-line qunit/no-identical-names */
    QUnit.module('when local and server time are different', hooks => {
      hooks.beforeEach(() => {
        Object.assign(ENV, {CONTEXT_TIMEZONE: 'America/Chicago'})
        tz.preload('America/Chicago', chicago)
        mountComponent()
      })

      test('shows both local and context time suggestions for end date', () => {
        strictEqual(getDateTimeSuggestions('End Date').length, 2)
      })

      test('formats the end date for the local timezone', () => {
        const $suggestions = getDateTimeSuggestions('End Date')
        // Local is GMT
        strictEqual($suggestions[0].textContent, 'Local: Thu Dec 31, 2015 12:00pm')
      })

      test('formats the end date for the context timezone', () => {
        const $suggestions = getDateTimeSuggestions('End Date')
        // Course is in Chicago
        strictEqual($suggestions[1].textContent, 'Account: Thu Dec 31, 2015 6:00am')
      })
    })

    test('does not show local and server time for end date when they are the same', () => {
      mountComponent()
      strictEqual(getDateTimeSuggestions('End Date').length, 0)
    })
  })

  QUnit.module('"Close Date" input', () => {
    test('value is set to the grading period close date for an existing grading period', () => {
      mountComponent()
      equal(getDateInput('Close Date').value, 'Jan 7, 2016 12pm')
    })

    /* eslint-disable-next-line qunit/no-identical-names */
    QUnit.module('when local and server time are different', hooks => {
      hooks.beforeEach(() => {
        Object.assign(ENV, {CONTEXT_TIMEZONE: 'America/Chicago'})
        tz.preload('America/Chicago', chicago)
        mountComponent()
      })

      test('shows both local and context time suggestions for close date', () => {
        strictEqual(getDateTimeSuggestions('Close Date').length, 2)
      })

      test('formats the close date for the local timezone', () => {
        const $suggestions = getDateTimeSuggestions('Close Date')
        // Local is GMT
        strictEqual($suggestions[0].textContent, 'Local: Thu Jan 7, 2016 12:00pm')
      })

      test('formats the close date for the context timezone', () => {
        const $suggestions = getDateTimeSuggestions('Close Date')
        // Course is in Chicago
        strictEqual($suggestions[1].textContent, 'Account: Thu Jan 7, 2016 6:00am')
      })
    })

    test('updates to match "End Date" when not previously set and "End Date" changes', () => {
      props.period = null
      mountComponent()
      setDateInputValue('End Date', 'Dec 31, 2015 12pm')
      equal(getDateInput('Close Date').value, 'Dec 31, 2015 12pm')
    })

    test('updates to match "End Date" when currently matching "End Date" and "End Date" changes', () => {
      props.period.closeDate = props.period.endDate
      mountComponent()
      setDateInputValue('End Date', 'Dec 31, 2015 12pm')
      equal(getDateInput('Close Date').value, 'Dec 31, 2015 12pm')
    })

    test('does not update when not set equal to "End Date" and "End Date" changes', () => {
      mountComponent()
      setDateInputValue('End Date', 'Dec 31, 2015 12pm')
      equal(getDateInput('Close Date').value, 'Jan 7, 2016 12pm')
    })

    test('does not update when "End Date" changes to match and changes again', () => {
      mountComponent()
      setDateInputValue('End Date', 'Jan 7, 2016 12pm')
      setDateInputValue('End Date', 'Dec 31, 2015 12pm')
      equal(getDateInput('Close Date').value, 'Jan 7, 2016 12pm')
    })

    test('updates to match "End Date" after being cleared and "End Date" changes', () => {
      mountComponent()
      setDateInputValue('Close Date', '')
      setDateInputValue('End Date', 'Dec 31, 2015 12pm')
      equal(getDateInput('Close Date').value, 'Dec 31, 2015 12pm')
    })
  })

  QUnit.module('"Weight" input', () => {
    test('is present when the grading period set is weighted', () => {
      mountComponent()
      strictEqual(wrapper.find('input#weight').length, 1)
    })

    test('is absent when the grading period set is not weighted', () => {
      props.weighted = false
      mountComponent()
      strictEqual(wrapper.find('input#weight').length, 0)
    })

    test('value is set to the grading period weight for an existing grading period', () => {
      mountComponent()
      strictEqual(getInput('weight').value, '30')
    })
  })

  QUnit.module('"Save" button', () => {
    function getSavedGradingPeriod() {
      return props.onSave.lastCall.args[0]
    }

    test('calls the onSave callback when clicked', () => {
      mountComponent()
      getButton('Save').simulate('click')
      strictEqual(props.onSave.callCount, 1)
    })

    test('includes the grading period id when updating an existing grading period', () => {
      mountComponent()
      getButton('Save').simulate('click')
      strictEqual(getSavedGradingPeriod().id, '1401')
    })

    test('excludes the grading period id when creating a new grading period', () => {
      delete props.period.id
      mountComponent()
      getButton('Save').simulate('click')
      strictEqual(typeof getSavedGradingPeriod().id, 'undefined')
    })

    test('includes the grading period title', () => {
      mountComponent()
      getButton('Save').simulate('click')
      equal(getSavedGradingPeriod().title, 'Q1')
    })

    test('includes updates to the grading period title', () => {
      mountComponent()
      setInputValue('title', 'Quarter 1')
      getButton('Save').simulate('click')
      equal(getSavedGradingPeriod().title, 'Quarter 1')
    })

    test('includes the grading period start date', () => {
      mountComponent()
      getButton('Save').simulate('click')
      deepEqual(getSavedGradingPeriod().startDate, new Date('2015-11-01T12:00:00Z'))
    })

    test('includes updates to the grading period start date', () => {
      mountComponent()
      setDateInputValue('Start Date', 'Nov 2, 2015 12pm')
      getButton('Save').simulate('click')
      deepEqual(getSavedGradingPeriod().startDate, new Date('2015-11-02T12:00:00Z'))
    })

    test('includes the grading period end date', () => {
      mountComponent()
      getButton('Save').simulate('click')
      deepEqual(getSavedGradingPeriod().endDate, new Date('2015-12-31T12:00:00Z'))
    })

    test('includes updates to the grading period end date', () => {
      mountComponent()
      setDateInputValue('End Date', 'Dec 30, 2015 12pm')
      getButton('Save').simulate('click')
      deepEqual(getSavedGradingPeriod().endDate, new Date('2015-12-30T12:00:00Z'))
    })

    test('includes the grading period close date', () => {
      mountComponent()
      getButton('Save').simulate('click')
      deepEqual(getSavedGradingPeriod().closeDate, new Date('2016-01-07T12:00:00Z'))
    })

    test('includes updates to the grading period close date', () => {
      mountComponent()
      setDateInputValue('Close Date', 'Dec 31, 2015 12pm')
      getButton('Save').simulate('click')
      deepEqual(getSavedGradingPeriod().closeDate, new Date('2015-12-31T12:00:00Z'))
    })

    test('includes the grading period weight', () => {
      mountComponent()
      getButton('Save').simulate('click')
      strictEqual(getSavedGradingPeriod().weight, 30)
    })

    test('includes updates to the grading period weight', () => {
      mountComponent()
      setInputValue('weight', '25')
      getButton('Save').simulate('click')
      strictEqual(getSavedGradingPeriod().weight, 25)
    })

    test('is disabled when the form is disabled', () => {
      props.disabled = true
      mountComponent()
      strictEqual(getButton('Save').prop('disabled'), true)
    })

    test('is not disabled when the form is not disabled', () => {
      mountComponent()
      notEqual(getButton('Save').prop('disabled'), true)
    })
  })

  QUnit.module('"Cancel" button', () => {
    test('calls the onCancel callback when clicked', () => {
      mountComponent()
      getButton('Cancel').simulate('click')
      strictEqual(props.onCancel.callCount, 1)
    })

    test('is disabled when the form is disabled', () => {
      props.disabled = true
      mountComponent()
      strictEqual(getButton('Cancel').prop('disabled'), true)
    })

    test('is not disabled when the form is not disabled', () => {
      mountComponent()
      notEqual(getButton('Cancel').prop('disabled'), true)
    })
  })
})
