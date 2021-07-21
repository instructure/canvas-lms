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
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {showImportOutcomesModal} from '@canvas/outcomes/react/ImportOutcomesModal'
import {MockedProvider} from '@apollo/react-testing'

jest.mock('@canvas/rce/RichContentEditor')
jest.mock('@canvas/outcomes/react/ImportOutcomesModal')
jest.useFakeTimers()

const render = (children, {isMobileView = false, renderer = rtlRender} = {}) => {
  return renderer(
    <OutcomesContext.Provider value={{env: {isMobileView}}}>
      <MockedProvider mocks={[]}>{children}</MockedProvider>
    </OutcomesContext.Provider>
  )
}

describe('ManagementHeader', () => {
  const defaultProps = (props = {}) => ({
    handleFileDrop: () => {},
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
    const {getByText} = render(<ManagementHeader {...defaultProps()} />)
    expect(getByText('Import')).toBeInTheDocument()
    expect(getByText('Create')).toBeInTheDocument()
    expect(getByText('Find')).toBeInTheDocument()
  })

  it('calls showImportOutcomesModal when click on Import', () => {
    const props = defaultProps()
    const {getByText} = render(<ManagementHeader {...props} />)
    fireEvent.click(getByText('Import'))
    expect(showImportOutcomesModal).toHaveBeenCalledTimes(1)
    expect(showImportOutcomesModal).toHaveBeenCalledWith({onFileDrop: props.handleFileDrop})
  })

  it('opens FindOutcomesModal when Find button is clicked', async () => {
    const {getByText} = render(<ManagementHeader {...defaultProps()} />)
    fireEvent.click(getByText('Find'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
  })

  it('opens CreateOutcomeModal when Create button is clicked', async () => {
    const {getByText} = render(<ManagementHeader {...defaultProps()} />)
    fireEvent.click(getByText('Create'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Create Outcome')).toBeInTheDocument()
  })

  describe('Responsiveness', () => {
    it('renders only the Add Button', () => {
      const {getByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true
      })
      expect(getByText('Add')).toBeInTheDocument()
    })

    it('renders the Menu Items', () => {
      const {getByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true
      })
      fireEvent.click(getByText('Add'))
      expect(getByText('Import')).toBeInTheDocument()
      expect(getByText('Create')).toBeInTheDocument()
      expect(getByText('Find')).toBeInTheDocument()
    })

    it('calls showImportOutcomesModal when click on Import Menu Item', () => {
      const {getByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true
      })
      fireEvent.click(getByText('Add'))
      fireEvent.click(getByText('Import'))
      expect(showImportOutcomesModal).toHaveBeenCalledTimes(1)
    })

    it('opens FindOutcomesModal when Find Menu Item is clicked', async () => {
      const {getByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true
      })
      fireEvent.click(getByText('Add'))
      fireEvent.click(getByText('Find'))
      await act(async () => jest.runAllTimers())
      expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
    })

    it('opens CreateOutcomeModal when Create Menu Item is clicked', async () => {
      const {getByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true
      })
      fireEvent.click(getByText('Add'))
      fireEvent.click(getByText('Create'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Create Outcome')).toBeInTheDocument()
    })
  })
})
