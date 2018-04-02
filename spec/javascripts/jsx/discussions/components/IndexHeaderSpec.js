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
import { mount } from 'enzyme'
import merge from 'lodash/merge'

import IndexHeader from 'jsx/discussions/components/IndexHeader'

const makeProps = (props = {}) => merge({
  contextType: 'course',
  contextId: '1',
  userSettings: {mark_as_read: true},
  fetchUserSettings: () => {},
  permissions: {
    create: true,
    manage_content: true,
    moderate: true,
  },
  isBusy: false,
  selectedCount: 0,
  applicationElement: () => document.getElementById('fixtures'),
}, props)

QUnit.module('IndexHeader component')

test('renders the component', () => {
  const tree = mount(<IndexHeader {...makeProps()} />)
  const node = tree.find('IndexHeader')
  ok(node.exists())
})

test('renders the search input', () => {
  const props = makeProps()
  const tree = mount( <IndexHeader {...props} />)
  const select = tree.find('TextInput')
  ok(select.exists())
})

test('renders the filter input', () => {
  const props = makeProps()
  const tree = mount( <IndexHeader {...props} />)
  const filter = tree.find('Select')
  ok(filter.exists())
})

test('renders create discussion button if we have create permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { create: true } })} />
  )
  const node = tree.find('#add_discussion')
  ok(node.exists())
})

test('does not render create discussion button if we do not have create permissions', () => {
  const tree = mount(
    <IndexHeader {...makeProps({ permissions: { create: false } })} />
  )
  const node = tree.find('#add_discussion')
  notOk(node.exists())
})

test('renders discussionSettings', () => {
  const tree = mount(
    <IndexHeader {...makeProps()} />
  )
  const node = tree.find('#discussion_settings')
  ok(node.exists())
})

test('calls onFilterChange when entering a search term', (assert) => {
  const done = assert.async()
  const props = makeProps()
  const searchSpy = sinon.spy()
  props.searchDiscussions = searchSpy

  const tree = mount( <IndexHeader {...props} />)
  const select = tree.find('TextInput')
  const input = select.find('input')
  input.simulate('change', { target: { value: 'foobar' } })

  setTimeout(() => {
    ok(searchSpy.calledOnce)
    done()
  }, 750) // Need the longer timout here cause of debounce
})

test('calls onFilterChange when selecting a new filter', (assert) => {
  const done = assert.async()
  const props = makeProps()
  const filterSpy = sinon.spy()
  props.searchDiscussions = filterSpy

  const tree = mount( <IndexHeader {...props} />)
  const instuiSelect = tree.find('Select')
  const rawSelect = instuiSelect.find('select')
  rawSelect.simulate('change', { target: { value: 'unread' } })

  setTimeout(() => {
    ok(filterSpy.calledOnce)
    done()
  }, 750) // Need the longer timout here cause of debounce
})
