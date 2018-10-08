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

import ReactDOM from 'react-dom'
import {Simulate} from 'react-dom/test-utils'
import _ from 'underscore'
import setsApi from 'compiled/api/gradingPeriodSetsApi'
import NewSetForm from 'jsx/grading/NewGradingPeriodSetForm'
import * as FlashAlert from 'jsx/shared/FlashAlert'

const wrapper = document.getElementById('fixtures')

const assertDisabled = function(component) {
  const $el = ReactDOM.findDOMNode(component)
  equal($el.getAttribute('aria-disabled'), 'true')
}

const assertEnabled = function(component) {
  const $el = ReactDOM.findDOMNode(component)
  notEqual($el.getAttribute('aria-disabled'), 'true')
}

const exampleSet = {
  id: '81',
  title: 'Example Set!',
  weighted: false,
  displayTotalsForAllGradingPeriods: false,
  gradingPeriods: [],
  permissions: {read: true, update: true, delete: true, create: true},
  createdAt: '2013-06-03T02:57:42Z'
}

QUnit.module('NewGradingPeriodSetForm', {
  renderComponent(props = {}) {
    const defaultProps = {
      enrollmentTerms: [],
      closeForm() {},
      addGradingPeriodSet() {},
      urls: {
        gradingPeriodSetsURL: 'api/v1/accounts/1/grading_period_sets',
        enrollmentTermsURL: 'api/v1/accounts/1/enrollment_terms'
      },
      readOnly: false
    }
    const element = React.createElement(NewSetForm, _.defaults(props, defaultProps))
    return ReactDOM.render(element, wrapper)
  },

  stubCreateSuccess() {
    const success = Promise.resolve(exampleSet)
    sandbox.stub(setsApi, 'create').returns(success)
    return success
  },

  stubCreateFailure() {
    const failure = Promise.reject(new Error('FAIL'))
    sandbox.stub(setsApi, 'create').returns(failure)
    return failure
  },

  teardown() {
    FlashAlert.destroyContainer()
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('initially renders with the create button not disabled', function() {
  const form = this.renderComponent()
  assertEnabled(form.refs.createButton)
})

test('initially renders with the cancel button not disabled', function() {
  const form = this.renderComponent()
  assertEnabled(form.refs.cancelButton)
})

test('initially renders with the "Display totals for All Grading Periods option" checkbox unchecked', function() {
  const form = this.renderComponent()
  notOk(form.displayTotalsCheckbox._input.checked)
})

test('disables the create button when it is clicked', function() {
  const promise = this.stubCreateSuccess()
  const form = this.renderComponent()
  Simulate.change(form.refs.titleInput, {target: {value: 'Cash me ousside'}})
  Simulate.click(ReactDOM.findDOMNode(form.refs.createButton))
  return promise.then(() => {
    assertDisabled(form.refs.createButton)
  })
})

test('the "Display totals for All Grading Periods option" checkbox state is included when the set is created', function() {
  const promise = this.stubCreateSuccess()
  const addSetStub = sinon.stub()
  const form = this.renderComponent({addGradingPeriodSet: addSetStub})
  Simulate.change(form.refs.titleInput, {target: {value: 'Howbow dah'}})
  Simulate.click(ReactDOM.findDOMNode(form.refs.createButton))
  return promise.then(() => {
    equal(addSetStub.callCount, 1, 'addGradingPeriodSet was called once')
    const {displayTotalsForAllGradingPeriods} = addSetStub.getCall(0).args[0]
    equal(displayTotalsForAllGradingPeriods, false, 'includes displayTotalsForAllGradingPeriods')
  })
})

test('disables the cancel button when the create button is clicked', function() {
  const promise = this.stubCreateSuccess()
  const form = this.renderComponent()
  Simulate.change(form.refs.titleInput, {target: {value: 'Watch me whip'}})
  sandbox.stub(form, 'isValid').returns(true)
  Simulate.click(ReactDOM.findDOMNode(form.refs.createButton))
  return promise.then(() => {
    assertDisabled(form.refs.cancelButton)
  })
})

test('updates weighted state when checkbox is clicked', function() {
  const form = this.renderComponent()
  equal(form.state.weighted, false)
  form.weightedCheckbox.handleChange({target: {checked: true}})
  equal(form.state.weighted, true)
})

test('re-enables the cancel button when the ajax call fails', function() {
  const fakePromise = {
    then() {
      return fakePromise
    },
    catch(handler) {
      handler(new Error('FAIL'))
    }
  }
  sandbox.stub(setsApi, 'create').returns(fakePromise)
  const form = this.renderComponent()
  Simulate.change(form.refs.titleInput, {target: {value: 'Watch me nay nay'}})
  Simulate.click(ReactDOM.findDOMNode(form.refs.cancelButton))
  assertEnabled(form.refs.cancelButton)
})

test('re-enables the create button when the ajax call fails', function() {
  const fakePromise = {
    then() {
      return fakePromise
    },
    catch(handler) {
      handler(new Error('FAIL'))
    }
  }
  sandbox.stub(setsApi, 'create').returns(fakePromise)
  const form = this.renderComponent()
  Simulate.change(form.refs.titleInput, {target: {value: ':D'}})
  Simulate.click(ReactDOM.findDOMNode(form.refs.createButton))
  assertEnabled(form.refs.createButton)
})

test('showFlashAlert is not called when title is present', function() {
  const form = this.renderComponent()
  form.setState({title: 'foo'})
  const showFlashAlertStub = sandbox.stub(FlashAlert, 'showFlashAlert')
  form.isTitlePresent()
  strictEqual(showFlashAlertStub.callCount, 0)
})

test('showFlashAlert called when title is not present', function() {
  const form = this.renderComponent()
  const showFlashAlertStub = sandbox.stub(FlashAlert, 'showFlashAlert')
  form.isTitlePresent()
  strictEqual(showFlashAlertStub.callCount, 1)
})

test('showFlashAlert called with message when title is not present', function() {
  const form = this.renderComponent()
  const showFlashAlertStub = sandbox.stub(FlashAlert, 'showFlashAlert')
  form.isTitlePresent()
  deepEqual(showFlashAlertStub.firstCall.args[0], {
    type: 'error',
    message: 'A name for this set is required'
  })
})

test('submitSucceeded calls showFlashAlert once', function() {
  const form = this.renderComponent()
  const showFlashAlertStub = sandbox.stub(FlashAlert, 'showFlashAlert')
  form.submitSucceeded({})
  deepEqual(showFlashAlertStub.callCount, 1)
})

test('submitSucceeded calls showFlashAlert with message', function() {
  const form = this.renderComponent()
  const showFlashAlertStub = sandbox.stub(FlashAlert, 'showFlashAlert')
  form.submitSucceeded()
  deepEqual(showFlashAlertStub.firstCall.args[0], {
    type: 'success',
    message: 'Successfully created a set'
  })
})

test('submitFailed calls showFlashAlert once', function() {
  const form = this.renderComponent()
  const showFlashAlertStub = sandbox.stub(FlashAlert, 'showFlashAlert')
  form.submitFailed()
  deepEqual(showFlashAlertStub.callCount, 1)
})

test('submitFailed calls showFlashAlert with message', function() {
  const form = this.renderComponent()
  const showFlashAlertStub = sandbox.stub(FlashAlert, 'showFlashAlert')
  form.submitFailed()
  deepEqual(showFlashAlertStub.firstCall.args[0], {
    type: 'error',
    message: 'There was a problem submitting your set'
  })
})
