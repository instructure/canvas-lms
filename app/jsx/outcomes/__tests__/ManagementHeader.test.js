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
import {act, render as rtlRender, fireEvent} from '@testing-library/react'
import ManagementHeader from '../ManagementHeader'
import {showImportOutcomesModal} from '../ImportOutcomesModal'
import {MockedProvider} from '@apollo/react-testing'

jest.mock('../ImportOutcomesModal')
jest.useFakeTimers()

const render = children => {
  return rtlRender(<MockedProvider mocks={[]}>{children}</MockedProvider>)
}

describe('ManagementHeader', () => {
  it('renders Outcomes title', () => {
    const {getByText} = render(<ManagementHeader />)
    expect(getByText('Outcomes')).toBeInTheDocument()
  })

  it('renders Action Buttons', () => {
    const {getByText} = render(<ManagementHeader />)
    expect(getByText('Import')).toBeInTheDocument()
    expect(getByText('Create')).toBeInTheDocument()
    expect(getByText('Find')).toBeInTheDocument()
  })

  it('calls showImportOutcomesModal when click on Import', () => {
    const {getByText} = render(<ManagementHeader />)
    const importButton = getByText('Import')
    fireEvent.click(importButton)
    expect(showImportOutcomesModal).toHaveBeenCalledTimes(1)
  })

  it('opens FindOutcomesModal when Find button is clicked', async () => {
    const {getByText} = render(<ManagementHeader />)
    const findButton = getByText('Find')
    fireEvent.click(findButton)
    await act(async () => jest.runAllTimers())
    expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
  })
})
