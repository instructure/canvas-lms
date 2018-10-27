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
import GradingPeriod from 'jsx/grading/gradingPeriodTemplate'

const defaultProps = {
  title: 'Spring',
  weight: 50,
  weighted: false,
  startDate: new Date('2015-03-01T00:00:00Z'),
  endDate: new Date('2015-05-31T00:00:00Z'),
  closeDate: new Date('2015-06-07T00:00:00Z'),
  id: '1',
  permissions: {
    update: true,
    delete: true
  },
  disabled: false,
  readOnly: false,
  onDeleteGradingPeriod() {},
  onDateChange() {},
  onTitleChange() {}
}
const wrapper = document.getElementById('fixtures')

QUnit.module('GradingPeriod with read-only permissions', {
  renderComponent(opts = {}) {
    const readOnlyProps = {
      permissions: {
        update: false,
        delete: false
      }
    }
    const props = _.defaults(opts, readOnlyProps, defaultProps)
    const GradingPeriodElement = <GradingPeriod {...props} />
    return ReactDOM.render(GradingPeriodElement, wrapper)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('isNewGradingPeriod returns false if the id does not contain "new"', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.isNewGradingPeriod(), false)
})

test('isNewGradingPeriod returns true if the id contains "new"', function() {
  const gradingPeriod = this.renderComponent({id: 'new1'})
  ok(gradingPeriod.isNewGradingPeriod())
})

test('does not render a delete button', function() {
  const gradingPeriod = this.renderComponent()
  notOk(gradingPeriod.refs.deleteButton)
})

test('renders attributes as read-only', function() {
  const gradingPeriod = this.renderComponent()
  notEqual(gradingPeriod.refs.title.type, 'INPUT')
  notEqual(gradingPeriod.refs.startDate.type, 'INPUT')
  notEqual(gradingPeriod.refs.endDate.type, 'INPUT')
})

test('displays the correct attributes', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.title.textContent, 'Spring')
  equal(gradingPeriod.refs.startDate.textContent, 'Mar 1, 2015')
  equal(gradingPeriod.refs.endDate.textContent, 'May 31, 2015')
  equal(gradingPeriod.refs.weight, null)
})

test('displays the assigned close date', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.closeDate.textContent, 'Jun 7, 2015')
})

test('uses the end date when close date is not defined', function() {
  const gradingPeriod = this.renderComponent({closeDate: null})
  equal(gradingPeriod.refs.closeDate.textContent, 'May 31, 2015')
})

test('displays weight only when weighted is true', function() {
  const gradingPeriod = this.renderComponent({weighted: true})
  equal(gradingPeriod.refs.weight.textContent, '50%')
})

QUnit.module("GradingPeriod with 'readOnly' set to true", {
  renderComponent(opts = {}) {
    const readOnlyProps = {readOnly: true}
    const props = _.defaults(opts, readOnlyProps, defaultProps)
    const GradingPeriodElement = <GradingPeriod {...props} />
    return ReactDOM.render(GradingPeriodElement, wrapper)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('isNewGradingPeriod returns false if the id does not contain "new"', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.isNewGradingPeriod(), false)
})

test('isNewGradingPeriod returns true if the id contains "new"', function() {
  const gradingPeriod = this.renderComponent({id: 'new1'})
  ok(gradingPeriod.isNewGradingPeriod())
})

test('does not render a delete button', function() {
  const gradingPeriod = this.renderComponent()
  notOk(gradingPeriod.refs.deleteButton)
})

test('renders attributes as read-only', function() {
  const gradingPeriod = this.renderComponent()
  notEqual(gradingPeriod.refs.title.type, 'INPUT')
  notEqual(gradingPeriod.refs.startDate.type, 'INPUT')
  notEqual(gradingPeriod.refs.endDate.type, 'INPUT')
  equal(gradingPeriod.refs.weight, null)
})

test('displays the correct attributes', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.title.textContent, 'Spring')
  equal(gradingPeriod.refs.startDate.textContent, 'Mar 1, 2015')
  equal(gradingPeriod.refs.endDate.textContent, 'May 31, 2015')
  equal(gradingPeriod.refs.weight, null)
})

test('displays the assigned close date', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.closeDate.textContent, 'Jun 7, 2015')
})

test('uses the end date when close date is not defined', function() {
  const gradingPeriod = this.renderComponent({closeDate: null})
  equal(gradingPeriod.refs.closeDate.textContent, 'May 31, 2015')
})

QUnit.module('editable GradingPeriod', {
  renderComponent(opts = {}) {
    const props = _.defaults(opts, defaultProps)
    const GradingPeriodElement = <GradingPeriod {...props} />
    return ReactDOM.render(GradingPeriodElement, wrapper)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('renders a delete button', function() {
  const gradingPeriod = this.renderComponent()
  ok(gradingPeriod.refs.deleteButton)
})

test('renders with input fields', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.title.tagName, 'INPUT')
  equal(gradingPeriod.refs.startDate.tagName, 'INPUT')
  equal(gradingPeriod.refs.endDate.tagName, 'INPUT')
  equal(gradingPeriod.refs.weight, null)
})

test('displays the correct attributes', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.title.value, 'Spring')
  equal(gradingPeriod.refs.startDate.value, 'Mar 1, 2015')
  equal(gradingPeriod.refs.endDate.value, 'May 31, 2015')
  equal(gradingPeriod.refs.weight, null)
})

test('uses the end date for close date', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.closeDate.textContent, 'May 31, 2015')
})

test("calls onClick handler for clicks on 'delete grading period'", function() {
  const deleteSpy = sinon.spy()
  const gradingPeriod = this.renderComponent({onDeleteGradingPeriod: deleteSpy})
  Simulate.click(gradingPeriod.refs.deleteButton)
  ok(deleteSpy.calledOnce)
})

test("ignores clicks on 'delete grading period' when disabled", function() {
  const deleteSpy = sinon.spy()
  const gradingPeriod = this.renderComponent({
    onDeleteGradingPeriod: deleteSpy,
    disabled: true
  })
  Simulate.click(gradingPeriod.refs.deleteButton)
  notOk(deleteSpy.called)
})

QUnit.module('custom prop validation for editable periods', {
  renderComponent(opts = {}) {
    const props = _.defaults(opts, defaultProps)
    const GradingPeriodElement = <GradingPeriod {...props} />
    return ReactDOM.render(GradingPeriodElement, wrapper)
  },
  setup() {
    this.consoleError = sandbox.stub(console, 'error')
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('does not warn of invalid props if all required props are present and of the correct type', function() {
  this.renderComponent()
  ok(this.consoleError.notCalled)
})

test('warns if required props are missing', function() {
  this.renderComponent({disabled: null})
  ok(this.consoleError.calledOnce)
})

test('warns if required props are of the wrong type', function() {
  this.renderComponent({onDeleteGradingPeriod: 'invalid-type'})
  ok(this.consoleError.calledOnce)
})
