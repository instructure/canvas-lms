// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {render, fireEvent, waitForElementToBeRemoved} from '@testing-library/react'
import store from '../../lib/ExternalAppsStore'
import ExternalToolPlacementButton from '../ExternalToolPlacementButton'

jest.mock('../../lib/ExternalAppsStore')

// let this component's rendering be tested in other places and just focus on its presence
jest.mock('../ExternalToolPlacementList', () => ({tool}) => <div>{Object.keys(tool)}</div>)

describe('ExternalToolPlacementButton', () => {
  const tool = {
    name: 'test',
    app_type: 'ContextExternalTool',
  }

  const renderComponent = (overrides = {}) => {
    return render(
      <ExternalToolPlacementButton
        tool={tool}
        returnFocus={() => {}}
        onToggleSuccess={jest.fn()}
        {...overrides}
      />
    )
  }

  const mockFetchWithDetails = (overrides = {}) => {
    store.fetchWithDetails.mockImplementation(async () => ({...tool, ...overrides}))
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('with defaults', () => {
    it('renders a list item that opens the modal', () => {
      const {queryByRole} = renderComponent()
      expect(queryByRole('menuitem')).toBeInTheDocument()
    })

    it('clicking the list item opens the modal', async () => {
      mockFetchWithDetails()
      const {queryByRole, findByText} = renderComponent()
      fireEvent.click(queryByRole('menuitem'))
      expect(await findByText('App Placements')).toBeInTheDocument()
    })
  })

  describe('with type=button', () => {
    it('renders a button that opens the modal', () => {
      const {queryByRole} = renderComponent({type: 'button'})
      expect(queryByRole('button')).toBeInTheDocument()
    })

    it('clicking the button opens the modal', async () => {
      mockFetchWithDetails()
      const {queryByRole, findByText} = renderComponent({type: 'button'})
      fireEvent.click(queryByRole('button'))
      expect(await findByText('App Placements')).toBeInTheDocument()
    })
  })

  describe('with tool.app_type != ContextExternalTool', () => {
    it('does not render the modal', () => {
      const {queryByRole} = renderComponent({tool: {name: 'other tool', app_type: 'other'}})
      expect(queryByRole('button')).not.toBeInTheDocument()
    })
  })

  describe('when the modal opens', () => {
    it('renders spinner while tool details are being fetched', async () => {
      store.fetchWithDetails.mockImplementation(async () => {
        // wait for 1 second
        await new Promise(resolve => setTimeout(resolve, 1000))
        return tool
      })
      const {queryByRole, findByTitle, queryByTitle} = renderComponent()
      fireEvent.click(queryByRole('menuitem'))

      const spinnerTitle = 'Retrieving Tool'
      // spinner is rendered while waiting
      expect(await findByTitle(spinnerTitle)).toBeInTheDocument()
      // and is removed after fetchWithDetails resolves
      await waitForElementToBeRemoved(() => queryByTitle(spinnerTitle))
      expect(queryByTitle(spinnerTitle)).not.toBeInTheDocument()
    })

    it('renders child component in modal', async () => {
      // uses ExternalToolPlacementList mock at the top of this file
      mockFetchWithDetails()
      const {queryByRole, findByText} = renderComponent()
      fireEvent.click(queryByRole('menuitem'))
      expect(await findByText(/name/)).toBeInTheDocument()
    })

    it('merges fetched tool details while favoring props.tool', async () => {
      // uses ExternalToolPlacementList mock at the top of this file
      mockFetchWithDetails({new_property: 'nice'})
      const {queryByRole, findByText} = renderComponent()
      fireEvent.click(queryByRole('menuitem'))
      expect(await findByText(/new_property/)).toBeInTheDocument()
    })
  })
})
