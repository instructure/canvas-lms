/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import StudentFooter from '../StudentFooter'

import api from '../../apis/ContextModuleApi'

jest.mock('../../apis/ContextModuleApi')

describe('StudentFooter', () => {
  let nextModule
  let previousModule

  let setOnFailure

  let defaultProps

  const renderComponent = (customProps = {}) => {
    setOnFailure = jest.fn()

    return render(
      <AlertManagerContext.Provider value={{setOnFailure}}>
        <StudentFooter {...defaultProps} {...customProps} />
      </AlertManagerContext.Provider>
    )
  }

  beforeEach(() => {
    nextModule = {url: '/next', tooltipText: {string: 'Next Module'}}
    previousModule = {url: '/previous', tooltipText: {string: 'Previous Module'}}

    defaultProps = {}

    api.getContextModuleData.mockClear()
    api.getContextModuleData.mockImplementation(() =>
      Promise.resolve({next: nextModule, previous: previousModule})
    )
  })

  it('renders passed-in elements in order', async () => {
    const buttons = [
      {key: 'item1', element: <div data-testid="child-item">item 1</div>},
      {key: 'item2', element: <div data-testid="child-item">item 2</div>},
      {key: 'item3', element: <div data-testid="child-item">item 3</div>},
      {key: 'item4', element: <div data-testid="child-item">item 4</div>},
    ]

    previousModule = null
    nextModule = null

    const {findAllByTestId} = render(<StudentFooter buttons={buttons} />)
    expect((await findAllByTestId('child-item')).map(element => element.innerHTML)).toEqual([
      'item 1',
      'item 2',
      'item 3',
      'item 4',
    ])
  })

  describe('modules', () => {
    beforeEach(() => {
      defaultProps = {assignmentID: '100', courseID: '200'}
    })

    it('requests module information using the supplied properties passed in', async () => {
      renderComponent()

      await waitFor(() => {
        expect(api.getContextModuleData).toHaveBeenCalledWith('200', '100')
      })
    })

    it('does not request module information if the assignment and course ID are not provided', async () => {
      renderComponent({assignmentID: null, courseID: null})
      expect(api.getContextModuleData).not.toHaveBeenCalled()
    })

    describe('while the request is in progress', () => {
      beforeEach(() => {
        api.getContextModuleData.mockReturnValue(new Promise(() => {}))
      })

      it('only renders the supplied items', () => {
        const buttons = [{key: 'item1', element: <div data-testid="child-item">item 1</div>}]

        const {getByTestId, queryByRole} = renderComponent({buttons})
        expect(getByTestId('child-item')).toBeInTheDocument()
        expect(queryByRole('link', {name: /Previous/})).not.toBeInTheDocument()
      })
    })

    describe('when the request succeeds', () => {
      it('renders a link to the previous module if it exists', async () => {
        const {findByRole} = renderComponent()

        const previousLink = await findByRole('link', {name: /Previous/})
        expect(previousLink).toHaveAttribute('href', '/previous')

        fireEvent.mouseOver(previousLink)
        const previousTooltip = await findByRole('tooltip', {name: /Previous Module/})
        expect(previousTooltip).toBeInTheDocument()

        expect(previousLink).toHaveAttribute('aria-describedby', previousTooltip.id)
      })

      it('does not render a link to the previous module if it does not exist', async () => {
        previousModule = null

        const {queryByRole} = renderComponent()
        await waitFor(() => expect(api.getContextModuleData).toHaveBeenCalled())
        expect(queryByRole('link', {name: /Previous/})).not.toBeInTheDocument()
      })

      it('renders a link to the next module if it exists', async () => {
        const {findByRole} = renderComponent()

        const nextLink = await findByRole('link', {name: /Next/})
        expect(nextLink).toHaveAttribute('href', '/next')

        fireEvent.mouseOver(nextLink)
        const nextTooltip = await findByRole('tooltip', {name: /Next Module/})
        expect(nextTooltip).toBeInTheDocument()

        expect(nextLink).toHaveAttribute('aria-describedby', nextTooltip.id)
      })

      it('does not render a link to the next module if it does not exist', async () => {
        nextModule = null

        const {queryByRole} = renderComponent()
        await waitFor(() => expect(api.getContextModuleData).toHaveBeenCalled())
        expect(queryByRole('link', {name: /Next/})).not.toBeInTheDocument()
      })
    })

    it('displays an error when the request fails', async () => {
      api.getContextModuleData.mockRejectedValue(new Error('ouch'))

      renderComponent()
      await waitFor(() =>
        expect(setOnFailure).toHaveBeenCalledWith('There was a problem loading module information.')
      )
    })
  })
})
