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
import * as enzyme from 'enzyme'
import CourseFilter from 'jsx/blueprint_courses/components/CourseFilter'
import getSampleData from '../getSampleData'

QUnit.module('CourseFilter component')

const defaultProps = () => ({
  subAccounts: getSampleData().subAccounts,
  terms: getSampleData().terms,
})

test('renders the CourseFilter component', () => {
  const tree = enzyme.shallow(<CourseFilter {...defaultProps()} />)
  const node = tree.find('.bca-course-filter')
  ok(node.exists())
})

test('onChange fires with search filter when text is entered in search box', (assert) => {
  const done = assert.async()
  const props = defaultProps()
  props.onChange = (filter) => {
    equal(filter.search, 'giraffe')
    done()
  }
  const tree = enzyme.mount(<CourseFilter {...props} />)
  const input = tree.find('TextInput input')
  input.instance().value = 'giraffe'
  input.simulate('change')
})

test('onChange fires with term filter when term is selected', (assert) => {
  const done = assert.async()
  const props = defaultProps()
  props.onChange = (filter) => {
    equal(filter.term, '1')
    done()
  }
  const tree = enzyme.mount(<CourseFilter {...props} />)
  const input = tree.find('select').at(0)
  input.instance().value = '1'
  input.simulate('change')
})

test('onChange fires with subaccount filter when a subaccount is selected', (assert) => {
  const done = assert.async()
  const props = defaultProps()
  props.onChange = (filter) => {
    equal(filter.subAccount, '1')
    done()
  }
  const tree = enzyme.mount(<CourseFilter {...props} />)
  const input = tree.find('select').at(1)
  input.instance().value = '1'
  input.simulate('change')
})

test('onActivate fires when filters are focussed', () => {
  const props = defaultProps()
  props.onActivate = sinon.spy()
  const tree = enzyme.mount(<CourseFilter {...props} />)
  const input = tree.find('TextInput input')
  input.simulate('focus')
  ok(props.onActivate.calledOnce)
})

test('onChange not fired when < 3 chars are entered in search text input', (assert) => {
  const done = assert.async()
  const props = defaultProps()
  props.onChange = sinon.spy()
  const tree = enzyme.mount(<CourseFilter {...props} />)
  const input = tree.find('input[type="search"]')
  input.instance().value = 'aa'
  input.simulate('change')
  setTimeout(() => {
    equal(props.onChange.callCount, 0)
    done()
  }, 0)
})

test('onChange fired when 3 chars are entered in search text input', (assert) => {
  const done = assert.async()
  const props = defaultProps()
  props.onChange = sinon.spy()
  const tree = enzyme.mount(<CourseFilter {...props} />)
  const input = tree.find('input[type="search"]')
  input.instance().value = 'aaa'
  input.simulate('change')
  setTimeout(() => {
    ok(props.onChange.calledOnce)
    done()
  }, 0)
})
