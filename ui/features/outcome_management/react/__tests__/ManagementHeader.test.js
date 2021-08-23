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

const render = (
  children,
  {isMobileView = false, canManage = true, canImport = true, renderer = rtlRender} = {}
) => {
  return renderer(
    <OutcomesContext.Provider value={{env: {isMobileView, canManage, canImport}}}>
      <MockedProvider mocks={[]}>{children}</MockedProvider>
    </OutcomesContext.Provider>
  )
}

describe('ManagementHeader', () => {
  const defaultProps = (props = {}) => ({
    handleFileDrop: () => {},
    canManage: true,
    canImport: true,
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

  describe('User does not have manage_outcomes permissions', () => {
    it('Create button does not appear', () => {
      const {queryByText} = render(<ManagementHeader {...defaultProps()} />, {
        canManage: false
      })
      expect(queryByText('Create')).not.toBeInTheDocument()
    })

    it('Find button does not appear', () => {
      const {queryByText} = render(<ManagementHeader {...defaultProps()} />, {
        canManage: false
      })
      expect(queryByText('Find')).not.toBeInTheDocument()
    })

    it('Import button does appear if user has import_outcomes permissions', () => {
      const {getByText} = render(<ManagementHeader {...defaultProps()} />, {
        canManage: false
      })
      expect(getByText('Import')).toBeInTheDocument()
    })
  })

  describe('User does not have import_outcomes permissions', () => {
    it('Import button does not appear', () => {
      const {queryByText} = render(<ManagementHeader {...defaultProps()} />, {
        canImport: false
      })
      expect(queryByText('Import')).not.toBeInTheDocument()
    })

    it('Create button does appear if user has manage_outcomes permissions', () => {
      const {queryByText} = render(<ManagementHeader {...defaultProps()} />, {
        canImport: false
      })
      expect(queryByText('Create')).toBeInTheDocument()
    })

    it('Find button does appear if user has manage_outcomes permissions', () => {
      const {getByText} = render(<ManagementHeader {...defaultProps()} />, {
        canManage: true
      })
      expect(getByText('Find')).toBeInTheDocument()
    })
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

    it("doesnt render the Add button if user can't import or manage outcomes", () => {
      const {queryByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true,
        canManage: false,
        canImport: false
      })
      expect(queryByText('Add')).not.toBeInTheDocument()
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

    it('only renders Import Menu Item if user only has import permissions', () => {
      const {getByText, queryByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true,
        canManage: false
      })
      fireEvent.click(getByText('Add'))
      expect(getByText('Import')).toBeInTheDocument()
      expect(queryByText('Create')).not.toBeInTheDocument()
      expect(queryByText('Find')).not.toBeInTheDocument()
    })

    it('only renders Create and Find Menu Items if user only has manage permissions', () => {
      const {getByText, queryByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true,
        canImport: false
      })
      fireEvent.click(getByText('Add'))
      expect(queryByText('Import')).not.toBeInTheDocument()
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

    it('opens FindOutcomesModal when Find Menu Item is clicked', () => {
      const {getByText} = render(<ManagementHeader {...defaultProps()} />, {
        isMobileView: true
      })
      fireEvent.click(getByText('Add'))
      fireEvent.click(getByText('Find'))
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
