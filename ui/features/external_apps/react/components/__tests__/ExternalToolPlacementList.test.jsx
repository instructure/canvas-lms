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
import {fireEvent, render, waitForElementToBeRemoved} from '@testing-library/react'
import store from '../../lib/ExternalAppsStore'
import ExternalToolPlacementList from '../ExternalToolPlacementList'

jest.mock('../../lib/ExternalAppsStore')

describe('ExternalToolPlacementList', () => {
  const tool = (overrides = {}) => ({
    name: 'test',
    app_type: 'ContextExternalTool',
    version: '1.3',
    context: 'account',
    ...overrides,
  })

  const renderComponent = (overrides = {}) => {
    return render(
      <ExternalToolPlacementList tool={tool()} onToggleSuccess={() => {}} {...overrides} />
    )
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('with 1.3 tool with no placements', () => {
    it('tells user no placements are enabled', () => {
      const {queryByText} = renderComponent()
      expect(queryByText(/No Placements Enabled/)).toBeInTheDocument()
    })
  })

  describe('with 1.3 tool', () => {
    it('lists enabled placements', () => {
      const {queryByText} = renderComponent({
        tool: tool({homework_submission: {enabled: true}, editor_button: {enabled: false}}),
      })
      expect(queryByText(/Homework Submission/)).toBeInTheDocument()
      expect(queryByText(/Editor Button/)).not.toBeInTheDocument()
    })

    it('shows assignment_ and link_selection if tool has resource_selection enabled', () => {
      const {queryByText} = renderComponent({
        tool: tool({resource_selection: {enabled: true}, assignment_selection: {enabled: true}}),
      })
      expect(queryByText(/Assignment Selection/)).toBeInTheDocument()
      expect(queryByText(/Link Selection/)).toBeInTheDocument()
    })
  })

  describe('with 1.1 tool with no configured placements', () => {
    describe('when not_selectable is false', () => {
      it('shows default placement text', () => {
        const {queryByText} = renderComponent({tool: tool({version: '1.1', not_selectable: false})})
        expect(queryByText(/Assignment and Link Selection/)).toBeInTheDocument()
      })
    })

    describe('when not_selectable is true', () => {
      it('shows no placements', () => {
        const {queryByText} = renderComponent({tool: tool({version: '1.1', not_selectable: true})})
        expect(queryByText(/No Placements Enabled/)).toBeInTheDocument()
      })
    })
  })

  describe('with 1.1 tool', () => {
    describe('if any default placements are enabled', () => {
      const toolOverrides = {
        version: '1.1',
        not_selectable: false,
        assignment_selection: {enabled: true},
      }

      it('shows default placement text', () => {
        const {queryByText} = renderComponent({
          tool: tool(toolOverrides),
        })
        expect(queryByText(/Assignment and Link Selection/)).toBeInTheDocument()
      })

      it('does not show text for specific default placements', () => {
        const {queryByText} = renderComponent({
          tool: tool(toolOverrides),
        })
        expect(queryByText(/Assignment Selection/)).not.toBeInTheDocument()
      })
    })

    it('lists enabled placements', () => {
      const {queryByText} = renderComponent({
        tool: tool({
          version: '1.1',
          not_selectable: true,
          homework_submission: {enabled: true},
          editor_button: {enabled: false},
        }),
      })
      expect(queryByText(/Homework Submission/)).toBeInTheDocument()
      expect(queryByText(/Editor Button/)).not.toBeInTheDocument()
    })
  })

  describe('with 1.1 tool in an editable context', () => {
    let oldEnv

    beforeAll(() => {
      oldEnv = window.ENV
      window.ENV = {
        PERMISSIONS: {create_tool_manually: true, edit_tool_manually: true},
        CONTEXT_BASE_URL: '/accounts/1',
      }
      store.togglePlacements.mockImplementation(({onSuccess}) => onSuccess())
    })

    afterAll(() => {
      window.ENV = oldEnv
    })

    it('shows notice about caching', () => {
      const {getByText} = renderComponent({
        tool: tool({
          version: '1.1',
          not_selectable: false,
        }),
      })
      expect(getByText(/It may take some time/)).toBeInTheDocument()
    })

    it('shows toggle buttons along with placement names', () => {
      const {getByRole} = renderComponent({
        tool: tool({
          version: '1.1',
          not_selectable: false,
        }),
      })
      expect(getByRole('button', {name: /Placement active/})).toBeInTheDocument()
    })

    describe('when placement is active', () => {
      it('shows checkmark', () => {
        renderComponent({
          tool: tool({
            version: '1.1',
            not_selectable: false,
          }),
        })
        expect(document.querySelector('svg').getAttribute('name')).toBe('IconCheckMark')
      })

      it('shows Active tooltip', () => {
        const {getByRole} = renderComponent({
          tool: tool({
            version: '1.1',
            not_selectable: false,
          }),
        })
        expect(getByRole('tooltip', {name: /Active/})).toBeInTheDocument()
      })
    })

    describe('when placement is inactive', () => {
      it('shows X', () => {
        renderComponent({
          tool: tool({
            version: '1.1',
            not_selectable: true,
          }),
        })
        expect(document.querySelector('svg').getAttribute('name')).toBe('IconEnd')
      })

      it('shows Inactive tooltip', () => {
        const {getByRole} = renderComponent({
          tool: tool({
            version: '1.1',
            not_selectable: true,
          }),
        })
        expect(getByRole('tooltip', {name: /Inactive/})).toBeInTheDocument()
      })
    })

    describe('when clicking toggle', () => {
      it('toggles placement that was clicked', () => {
        const {getByRole} = renderComponent({
          tool: tool({
            version: '1.1',
            not_selectable: false,
            homework_submission: {enabled: false},
          }),
        })
        fireEvent.click(getByRole('button', {name: /Placement inactive/}))
        expect(store.togglePlacements).toHaveBeenCalledWith(
          expect.objectContaining({
            tool: expect.objectContaining({homework_submission: {enabled: true}}),
            placements: ['homework_submission'],
          })
        )
      })

      it('shows spinner during API request', async () => {
        store.togglePlacements.mockImplementationOnce(async ({onSuccess}) => {
          await new Promise(resolve => setTimeout(resolve, 500))
          onSuccess()
        })

        const {findByTitle, getByRole, queryByTitle} = renderComponent({
          tool: tool({
            version: '1.1',
            not_selectable: false,
          }),
        })
        fireEvent.click(getByRole('button', {name: /Placement active/}))

        const spinnerTitle = 'Toggling Placement'
        // spinner is rendered while waiting
        expect(await findByTitle(spinnerTitle)).toBeInTheDocument()
        // and is removed after API request resolves
        await waitForElementToBeRemoved(() => queryByTitle(spinnerTitle))
        expect(queryByTitle(spinnerTitle)).not.toBeInTheDocument()
      })

      describe('when default placement is clicked', () => {
        it('toggles not_selectable', () => {
          const {getByRole} = renderComponent({
            tool: tool({
              version: '1.1',
              not_selectable: false,
            }),
          })
          fireEvent.click(getByRole('button', {name: /Placement active/}))
          expect(store.togglePlacements).toHaveBeenCalledWith(
            expect.objectContaining({
              tool: expect.objectContaining({not_selectable: true}),
              placements: [],
            })
          )
        })

        it('toggles included default placements', () => {
          const {getByRole} = renderComponent({
            tool: tool({
              version: '1.1',
              not_selectable: false,
              assignment_selection: {enabled: true},
            }),
          })
          fireEvent.click(getByRole('button', {name: /Placement active/}))
          expect(store.togglePlacements).toHaveBeenCalledWith(
            expect.objectContaining({
              tool: expect.objectContaining({not_selectable: true}),
              placements: ['assignment_selection'],
            })
          )
        })
      })

      it('changes enabled to false for placement that does not have enabled defined', () => {
        const {getByRole} = renderComponent({
          tool: tool({
            version: '1.1',
            not_selectable: true,
            homework_submission: {},
          }),
        })
        fireEvent.click(getByRole('button', {name: /Placement active/}))
        expect(store.togglePlacements).toHaveBeenCalledWith(
          expect.objectContaining({
            tool: expect.objectContaining({homework_submission: {enabled: false}}),
            placements: ['homework_submission'],
          })
        )
      })

      it('calls props.onToggleSuccess', () => {
        const onToggleSuccess = jest.fn()
        const {getByRole} = renderComponent({
          onToggleSuccess,
          tool: tool({
            version: '1.1',
            not_selectable: false,
            homework_submission: {enabled: false},
          }),
        })
        fireEvent.click(getByRole('button', {name: /Placement inactive/}))
        expect(onToggleSuccess).toHaveBeenCalled()
      })

      describe('when API request fails', () => {
        it('reverts toggle', async () => {
          store.togglePlacements.mockImplementationOnce(async ({onError}) => {
            await new Promise(resolve => setTimeout(resolve, 500))
            onError()
          })

          const {getByRole, queryByTitle} = renderComponent({
            tool: tool({
              version: '1.1',
              not_selectable: false,
            }),
          })
          fireEvent.click(getByRole('button', {name: /Placement active/}))

          // button turns into spinner during request
          await waitForElementToBeRemoved(() => queryByTitle('Toggling Placement'))
          // and then turns back to enabled when the request fails
          expect(document.querySelector('svg').getAttribute('name')).toBe('IconCheckMark')
        })
      })
    })

    describe('when clicking toggle for default placements', () => {
      it('includes default placements that the tool has configured', () => {
        const {getByRole} = renderComponent({
          tool: tool({
            version: '1.1',
            not_selectable: false,
            assignment_selection: {enabled: true},
          }),
        })
        fireEvent.click(getByRole('button', {name: /Placement active/}))
        expect(store.togglePlacements).toHaveBeenCalledWith(
          expect.objectContaining({placements: ['assignment_selection']})
        )
      })
    })
  })
})
