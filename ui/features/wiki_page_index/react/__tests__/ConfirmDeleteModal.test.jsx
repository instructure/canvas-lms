/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import '@instructure/canvas-theme'
import React from 'react'
import {shallow} from 'enzyme'
import ConfirmDeleteModal from '../ConfirmDeleteModal'
import Modal from '@canvas/instui-bindings/react/InstuiModal'

const defaultProps = () => ({
  pageTitles: ['page_1'],
  onConfirm: () => Promise.resolve({}),
})

test('renders the ConfirmDeleteModal component', () => {
  const modal = shallow(<ConfirmDeleteModal {...defaultProps()} />)
  expect(modal.exists()).toBe(true)
})

test('renders cancel and delete button', () => {
  const modal = shallow(<ConfirmDeleteModal {...defaultProps()} />)
  const node = modal.find('Button')
  expect(node.length).toEqual(2)
})

test('closes the ConfirmDeleteModal when cancel pressed', () => {
  const modal = shallow(<ConfirmDeleteModal {...defaultProps()} />)
  const cancel = modal.find('Button').first()
  cancel.simulate('click')
  expect(modal.state().show).toBe(false)
})

test('shows spinner on delete', () => {
  const modal = shallow(<ConfirmDeleteModal {...defaultProps()} />)
  const deleteBtn = modal.find('Button').at(1)
  deleteBtn.simulate('click')
  expect(modal.find('Spinner').exists()).toBe(true)
})

test('renders provided page titles', () => {
  const modal = shallow(<ConfirmDeleteModal {...defaultProps()} />)
  expect(modal.find(Modal.Body).render().text()).toMatch(/page_1/)
})
