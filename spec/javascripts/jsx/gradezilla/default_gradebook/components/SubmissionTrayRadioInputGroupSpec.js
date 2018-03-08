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

import React from 'react'
import {mount} from 'enzyme'
import SubmissionTrayRadioInputGroup from 'jsx/gradezilla/default_gradebook/components/SubmissionTrayRadioInputGroup'

QUnit.module('SubmissionTrayRadioInputGroup', {
  mountComponent(customProps) {
    const props = {
      colors: {
        late: '#FEF7E5',
        missing: '#F99',
        excused: '#E5F3FC'
      },
      disabled: false,
      latePolicy: {lateSubmissionInterval: 'day'},
      locale: 'en',
      submission: {excused: false, late: false, missing: false, secondsLate: 0},
      submissionUpdating: false,
      updateSubmission() {},
      ...customProps
    }
    return mount(<SubmissionTrayRadioInputGroup {...props} />)
  },

  getRadioOption(value) {
    return this.wrapper.find(`input[type="radio"][value="${value}"]`).node
  },

  teardown() {
    this.wrapper.unmount()
  }
})

test('renders FormFieldGroup enabled if disabled is false', function() {
  this.wrapper = this.mountComponent({disabled: false})
  strictEqual(this.wrapper.find('FormFieldGroup').props().disabled, false)
})

test('renders FormFieldGroup disabled if disabled is true', function() {
  this.wrapper = this.mountComponent({disabled: true})
  strictEqual(this.wrapper.find('FormFieldGroup').props().disabled, true)
})

test('renders all SubmissionTrayRadioInputs enabled if disabled is false', function() {
  this.wrapper = this.mountComponent({disabled: false})
  const inputDisabledStatus = this.wrapper
    .find('SubmissionTrayRadioInput')
    .map(input => input.props().disabled)
  deepEqual(inputDisabledStatus, [false, false, false, false])
})

test('renders all SubmissionTrayRadioInputs disabled if disabled is false', function() {
  this.wrapper = this.mountComponent({disabled: true})
  const inputDisabledStatus = this.wrapper
    .find('SubmissionTrayRadioInput')
    .map(input => input.props().disabled)
  deepEqual(inputDisabledStatus, [true, true, true, true])
})

test('renders with "none" selected if the submission is not late, missing, or excused', function() {
  this.wrapper = this.mountComponent()
  const radio = this.getRadioOption('none')
  strictEqual(radio.checked, true)
})

test('renders with "Excused" selected if the submission is excused', function() {
  this.wrapper = this.mountComponent({
    submission: {excused: true, late: false, missing: false, secondsLate: 0}
  })
  const radio = this.getRadioOption('excused')
  strictEqual(radio.checked, true)
})

test('renders with "Excused" selected if the submission is excused and also late', function() {
  this.wrapper = this.mountComponent({
    submission: {excused: true, late: true, missing: false, secondsLate: 0}
  })
  const radio = this.getRadioOption('excused')
  strictEqual(radio.checked, true)
})

test('renders with "Excused" selected if the submission is excused and also missing', function() {
  this.wrapper = this.mountComponent({
    submission: {excused: true, late: false, missing: true, secondsLate: 0}
  })
  const radio = this.getRadioOption('excused')
  strictEqual(radio.checked, true)
})

test('renders with "Late" selected if the submission is not excused and is late', function() {
  this.wrapper = this.mountComponent({
    submission: {excused: false, late: true, missing: false, secondsLate: 60}
  })
  const radio = this.getRadioOption('late')
  strictEqual(radio.checked, true)
})

test('renders with "Missing" selected if the submission is not excused and is missing', function() {
  this.wrapper = this.mountComponent({
    submission: {excused: false, late: false, missing: true, secondsLate: 0}
  })
  const radio = this.getRadioOption('missing')
  strictEqual(radio.checked, true)
})

test('handleRadioInputChanged calls updateSubmission with the late policy status for the selected radio input', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: 'missing'}}
  this.wrapper.instance().handleRadioInputChanged(event)
  strictEqual(updateSubmission.callCount, 1)
  deepEqual(updateSubmission.getCall(0).args[0], {latePolicyStatus: 'missing'})
})

test('handleRadioInputChanged calls updateSubmission with secondsLateOverride set to 0 if the "late" option is selected', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: 'late'}}
  this.wrapper.instance().handleRadioInputChanged(event)
  strictEqual(updateSubmission.callCount, 1)
  deepEqual(updateSubmission.getCall(0).args[0], {latePolicyStatus: 'late', secondsLateOverride: 0})
})

test('handleRadioInputChanged calls updateSubmission with excuse set to true if the "excused" option is selected', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: 'excused'}}
  this.wrapper.instance().handleRadioInputChanged(event)
  strictEqual(updateSubmission.callCount, 1)
  deepEqual(updateSubmission.getCall(0).args[0], {excuse: true})
})

test('handleRadioInputChanged does not call updateSubmission if the radio input is already selected', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: 'none'}}
  this.wrapper.instance().handleRadioInputChanged(event)
  strictEqual(updateSubmission.callCount, 0)
})

test('handleRadioInputChanged does not call updateSubmission if there is already a submission update in-flight', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission, submissionUpdating: true})
  const event = {target: {value: 'missing'}}
  this.wrapper.instance().handleRadioInputChanged(event)
  strictEqual(updateSubmission.callCount, 0)
})

test('handleNumberInputBlur does not call updateSubmission if the input value is an empty string', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: ''}}
  this.wrapper.instance().handleNumberInputBlur(event)
  strictEqual(updateSubmission.callCount, 0)
})

test('handleNumberInputBlur does not call updateSubmission if the input value cannot be parsed as a number', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: 'foo'}}
  this.wrapper.instance().handleNumberInputBlur(event)
  strictEqual(updateSubmission.callCount, 0)
})

test('handleNumberInputBlur calls updateSubmission if the input can be parsed as a number', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: '2'}}
  this.wrapper.instance().handleNumberInputBlur(event)
  strictEqual(updateSubmission.callCount, 1)
})

test('handleNumberInputBlur calls updateSubmission with latePolicyStatus set to "late"', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: '2'}}
  this.wrapper.instance().handleNumberInputBlur(event)
  strictEqual(updateSubmission.getCall(0).args[0].latePolicyStatus, 'late')
})

test('interval is hour: handleNumberInputBlur calls updateSubmission with the input converted to seconds', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({
    updateSubmission,
    latePolicy: {lateSubmissionInterval: 'hour'}
  })
  const event = {target: {value: '2'}}
  this.wrapper.instance().handleNumberInputBlur(event)
  strictEqual(updateSubmission.callCount, 1)
  const expectedSeconds = 2 * 3600
  strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
})

test('interval is day: handleNumberInputBlur calls updateSubmission with the input converted to seconds', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: '2'}}
  const expectedSeconds = 2 * 86400
  this.wrapper.instance().handleNumberInputBlur(event)
  strictEqual(updateSubmission.callCount, 1)
  strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
})

test('truncates the remainder if one exists', function() {
  const updateSubmission = this.stub()
  this.wrapper = this.mountComponent({updateSubmission})
  const event = {target: {value: '2.3737'}}
  const expectedSeconds = Math.trunc(2.3737 * 86400)
  this.wrapper.instance().handleNumberInputBlur(event)
  strictEqual(updateSubmission.callCount, 1)
  strictEqual(updateSubmission.getCall(0).args[0].secondsLateOverride, expectedSeconds)
})
