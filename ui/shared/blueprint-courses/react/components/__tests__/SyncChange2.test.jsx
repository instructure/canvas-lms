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
import {render, screen as rtlScreen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import SyncChange from '../SyncChange'
import getSampleData from './getSampleData'
import fakeENV from '@canvas/test-utils/fakeENV'

const defaultProps = () => ({
  change: getSampleData().history[0].changes[0],
})

describe('SyncChange component', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('renders the SyncChange component', () => {
    render(<SyncChange {...defaultProps()} />)
    expect(document.querySelector('.bcs__history-item__change')).toBeInTheDocument()
  })

  test('renders the SyncChange component expanded when clicked', async () => {
    const user = userEvent.setup()
    render(<SyncChange {...defaultProps()} />)

    const changeElement = document.querySelector('.bcs__history-item__change')
    await user.click(changeElement)

    expect(document.querySelector('.bcs__history-item__change__expanded')).toBeInTheDocument()
  })

  test('toggles isExpanded on click', async () => {
    const user = userEvent.setup()
    render(<SyncChange {...defaultProps()} />)

    const changeElement = document.querySelector('.bcs__history-item__change')

    expect(document.querySelector('.bcs__history-item__change__expanded')).not.toBeInTheDocument()

    await user.click(changeElement)
    expect(document.querySelector('.bcs__history-item__change__expanded')).toBeInTheDocument()

    await user.click(changeElement)
    expect(document.querySelector('.bcs__history-item__change__expanded')).not.toBeInTheDocument()
  })

  test('displays the correct exception count', () => {
    render(<SyncChange {...defaultProps()} />)
    expect(rtlScreen.getByText('3 exceptions')).toBeInTheDocument()
  })

  test('displays the correct exception types when expanded', async () => {
    const user = userEvent.setup()
    render(<SyncChange {...defaultProps()} />)

    const changeElement = document.querySelector('.bcs__history-item__change')
    await user.click(changeElement)

    expect(rtlScreen.getByText('Points changed exceptions:', {exact: false})).toBeInTheDocument()
    expect(rtlScreen.getByText('Default Term - Course 1')).toBeInTheDocument()

    expect(rtlScreen.getByText('Content changed exceptions:', {exact: false})).toBeInTheDocument()
    expect(rtlScreen.getByText('Default Term - Course 5')).toBeInTheDocument()

    expect(rtlScreen.getByText('Deleted content exceptions:', {exact: false})).toBeInTheDocument()
    expect(rtlScreen.getByText('Default Term - Course 56')).toBeInTheDocument()
  })
})
