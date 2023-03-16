/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import SRSearchMessage from '../SRSearchMessage'

injectGlobalAlertContainers()

const getProps = () => ({
  collection: {
    data: [1, 2, 3],
    links: {
      current: {
        url: 'abc',
        page: '5',
      },
      last: {
        url: 'abc10',
        page: '10',
      },
    },
  },
  dataType: 'Course',
})

it('returns noscript when the collection is loading', () => {
  const props = getProps()
  props.collection.loading = true
  const wrapper = mount(<SRSearchMessage {...props} />)
  expect(wrapper.find('noscript').exists()).toBe(true)
})

it('returns the error message when collection has an error', () => {
  const props = getProps()
  props.collection.error = new Error('failure')
  const wrapper = mount(<SRSearchMessage {...props} />)
  expect(wrapper.find('Alert').exists()).toBe(true)
  expect(document.getElementById('flash_screenreader_holder').textContent).toBe(
    'There was an error with your query; please try a different search'
  )
})
it('returns the empty course message when the collection is empty and the dataType is Course', () => {
  const props = getProps()
  props.collection.data = []
  const wrapper = mount(<SRSearchMessage {...props} />)
  expect(wrapper.find('Alert').exists()).toBe(true)
  expect(document.getElementById('flash_screenreader_holder').textContent).toBe('No courses found')
})
it('returns the empty user message when the collection is empty and the dataType is User', () => {
  const props = getProps()
  props.collection.data = []
  props.dataType = 'User'
  const wrapper = mount(<SRSearchMessage {...props} />)
  expect(wrapper.find('Alert').exists()).toBe(true)
  expect(document.getElementById('flash_screenreader_holder').textContent).toBe('No users found')
})
it('returns the course updated message when the dataType is Course', () => {
  const props = getProps()
  const wrapper = mount(<SRSearchMessage {...props} />)
  const alert = wrapper.find('Alert')
  expect(alert.exists()).toBe(true)
  expect(document.getElementById('flash_screenreader_holder').textContent).toBe(
    'Course results updated.'
  )
})
it('returns the user updated message when the dataType is User', () => {
  const props = getProps()
  props.dataType = 'User'
  const wrapper = mount(<SRSearchMessage {...props} />)
  const alert = wrapper.find('Alert')
  expect(alert.exists()).toBe(true)
  expect(document.getElementById('flash_screenreader_holder').textContent).toBe(
    'User results updated.'
  )
})
