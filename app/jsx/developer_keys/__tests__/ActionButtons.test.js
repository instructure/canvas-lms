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

import IconEyeLine from '@instructure/ui-icons/lib/Line/IconEye'

import ActionButtons from '../ActionButtons'

const props = ({ showVisibilityToggle = true } = {}) => {
  return {
    dispatch: jest.fn(),
    makeVisibleDeveloperKey: jest.fn(),
    makeInvisibleDeveloperKey: jest.fn(),
    deleteDeveloperKey: jest.fn(),
    editDeveloperKey: jest.fn(),
    developerKeysModalOpen: jest.fn(),
    developerKey:{
      id: '1',
      api_key: 'test',
      created_at: 'test'
    },
    visible: true,
    developerName: 'Unnamed Tool',
    onDelete: jest.fn(),
    showVisibilityToggle
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
