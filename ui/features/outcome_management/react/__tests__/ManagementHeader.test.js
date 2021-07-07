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
import {showImportOutcomesModal} from '@canvas/outcomes/react/ImportOutcomesModal'
import {MockedProvider} from '@apollo/react-testing'

jest.mock('@canvas/rce/RichContentEditor')
jest.mock('@canvas/outcomes/react/ImportOutcomesModal')
jest.useFakeTimers()

const render = children => {
  return rtlRender(<MockedProvider mocks={[]}>{children}</MockedProvider>)
}

describe('ManagementHeader', () => {
  const defaultProps = (props = {}) => ({
    breakpoints: {tablet: true},
    ...props
  })

  afterEach(() => {
    showImportOutcomesModal.mockRestore()
  })

  it('renders Outcomes title', () => {
    const {getByText} = render(<ManagementHeader />)
    expect(getByText('Outcomes')).toBeInTheDocument()
  })

  it('renders Action Buttons', () => {
    // breakpoints.tablet: true, meaning window.innerWidth >= 768px
    const {getByText} = render(<ManagementHeader {...defaultProps()} />)
    expect(getByText('Import')).toBeInTheDocument()
    expect(getByText('Create')).toBeInTheDocument()
    expect(getByText('Find')).toBeInTheDocument()
  })

  it('calls showImportOutcomesModal when click on Import', () => {
    // breakpoints.tablet: true, meaning window.innerWidth >= 768px
    const {getByText} = render(<ManagementHeader {...defaultProps()} />)
    fireEvent.click(getByText('Import'))
    expect(showImportOutcomesModal).toHaveBeenCalledTimes(1)
  })

  it('opens FindOutcomesModal when Find button is clicked', async () => {
    // breakpoints.tablet: true, meaning window.innerWidth >= 768px
    const {getByText} = render(<ManagementHeader {...defaultProps()} />)
    fireEvent.click(getByText('Find'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
  })

  it('opens CreateOutcomeModal when Create button is clicked', async () => {
    // breakpoints.tablet: true, meaning window.innerWidth >= 768px
    const {getByText} = render(<ManagementHeader {...defaultProps()} />)
    fireEvent.click(getByText('Create'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Create Outcome')).toBeInTheDocument()
  })

  describe('Responsiveness', () => {
    it('renders only the Add Button', () => {
      // breakpoints.tablet: false, meaning window.innerWidth < 768px
      const {getByText} = render(<ManagementHeader {...defaultProps({breakpoints: false})} />)
      expect(getByText('Add')).toBeInTheDocument()
    })

    it('renders the Menu Items', () => {
      // breakpoints.tablet: false, meaning window.innerWidth < 768px
      const {getByText} = render(<ManagementHeader {...defaultProps({breakpoints: false})} />)
      fireEvent.click(getByText('Add'))
      expect(getByText('Import')).toBeInTheDocument()
      expect(getByText('Create')).toBeInTheDocument()
      expect(getByText('Find')).toBeInTheDocument()
    })

    it('calls showImportOutcomesModal when click on Import Menu Item', () => {
      // breakpoints.tablet: false, meaning window.innerWidth < 768px
      const {getByText} = render(<ManagementHeader {...defaultProps({breakpoints: false})} />)
      fireEvent.click(getByText('Add'))
      fireEvent.click(getByText('Import'))
      expect(showImportOutcomesModal).toHaveBeenCalledTimes(1)
    })

    it('opens FindOutcomesModal when Find Menu Item is clicked', async () => {
      // breakpoints.tablet: false, meaning window.innerWidth < 768px
      const {getByText} = render(<ManagementHeader {...defaultProps({breakpoints: false})} />)
      fireEvent.click(getByText('Add'))
      fireEvent.click(getByText('Find'))
      await act(async () => jest.runAllTimers())
      expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
    })

    it('opens CreateOutcomeModal when Create Menu Item is clicked', async () => {
      // breakpoints.tablet: false, meaning window.innerWidth < 768px
      const {getByText} = render(<ManagementHeader {...defaultProps({breakpoints: false})} />)
      fireEvent.click(getByText('Add'))
      fireEvent.click(getByText('Create'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Create Outcome')).toBeInTheDocument()
    })
  })
})
