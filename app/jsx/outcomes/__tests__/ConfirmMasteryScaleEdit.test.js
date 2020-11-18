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
import React from 'react'
import ConfirmMasteryScaleEdit from '../ConfirmMasteryScaleEdit'
import {render, fireEvent} from '@testing-library/react'

const defaultProps = () => ({
  onConfirm: () => {},
  contextType: 'account',
  isOpen: true,
  onClose: () => {}
})

it('calls onClose and does not call onConfirm when canceled', () => {
  const onConfirm = jest.fn()
  const onClose = jest.fn()
  const {getByText} = render(
    <ConfirmMasteryScaleEdit {...defaultProps()} onConfirm={onConfirm} onClose={onClose} />
  )
  fireEvent.click(getByText('Cancel'))
  expect(onConfirm).not.toHaveBeenCalled()
  expect(onClose).toHaveBeenCalled()
})

it('does call onConfirm when saved', () => {
  const onConfirm = jest.fn()
  const {getByText} = render(<ConfirmMasteryScaleEdit {...defaultProps()} onConfirm={onConfirm} />)
  fireEvent.click(getByText('Save'))
  expect(onConfirm).toHaveBeenCalled()
})

describe('modal text', () => {
  it('renders correct text for an Account context', () => {
    const {getByText} = render(<ConfirmMasteryScaleEdit {...defaultProps()} />)
    expect(getByText(/all account and course level rubrics/)).not.toBeNull()
  })

  it('renders correct text for a Course context', () => {
    const {getByText} = render(<ConfirmMasteryScaleEdit {...defaultProps()} contextType="Course" />)
    expect(getByText(/all rubrics aligned to outcomes within this course/)).not.toBeNull()
  })
})
