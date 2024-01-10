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

import {IconEditLine, IconEyeLine} from '@instructure/ui-icons'

import ActionButtons from '../ActionButtons'

const props = ({
  showVisibilityToggle = true,
  developerKey = {
    id: '1',
    api_key: 'test',
    created_at: 'test',
  },
} = {}) => {
  return {
    dispatch: jest.fn(),
    makeVisibleDeveloperKey: jest.fn(),
    makeInvisibleDeveloperKey: jest.fn(),
    deleteDeveloperKey: jest.fn(),
    editDeveloperKey: jest.fn(),
    developerKeysModalOpen: jest.fn(),
    ltiKeysSetLtiKey: jest.fn(),
    contextId: '2',
    developerKey,
    visible: true,
    developerName: 'Unnamed Tool',
    onDelete: jest.fn(),
    showVisibilityToggle,
  }
}

it('renders visibility icon for Site Admin', () => {
  const wrapper = mount(<ActionButtons {...props()} />)
  expect(wrapper.find(IconEyeLine).exists()).toBe(true)
})

it('does not render visibility icon for root account', () => {
  const wrapper = mount(<ActionButtons {...props({showVisibilityToggle: false})} />)
  expect(wrapper.find(IconEyeLine).exists()).toBe(false)
})

it('renders edit button for non lti keys', () => {
  const wrapper = mount(<ActionButtons {...props()} />)
  expect(wrapper.find(IconEditLine).exists()).toBe(true)
})

it('renders edit button for lti registration keys', () => {
  const wrapper = mount(
    <ActionButtons
      {...props({
        developerKey: {
          id: '1',
          api_key: 'test',
          created_at: 'test',
          is_lti_key: true,
          is_lti_registration: true,
          ltiRegistration: {},
        },
      })}
    />
  )
  expect(wrapper.find(IconEditLine).exists()).toBe(true)
  expect(wrapper.find('a').prop('href')).toBe('/accounts/2/developer_keys/1')
})

it('renders edit button for lti keys', () => {
  const wrapper = mount(
    <ActionButtons
      {...props({
        developerKey: {
          id: '1',
          api_key: 'test',
          created_at: 'test',
          is_lti_key: true,
        },
      })}
    />
  )
  expect(wrapper.find(IconEditLine).exists()).toBe(true)
})

it('warns the user when deleting a LTI key', () => {
  const oldConfirm = window.confirm
  const wrapper = mount(
    <ActionButtons
      {...props({
        developerKey: {
          id: '1',
          api_key: 'test',
          created_at: 'test',
          is_lti_key: true,
        },
      })}
    />
  )

  window.confirm = jest.fn()
  wrapper.find('IconButton').at(4).simulate('click')
  expect(window.confirm).toHaveBeenCalledWith(
    'Are you sure you want to delete this developer key? This action will also delete all tools associated with the developer key in this context.'
  )
  window.confirm = oldConfirm
})
