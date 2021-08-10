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

import {fireEvent, render, waitFor} from '@testing-library/react'
import React from 'react'
import MentionDropdown from '../MentionDropdown'
import FakeEditor from '@instructure/canvas-rce/src/rce/plugins/shared/__tests__/FakeEditor'
import tinymce from 'tinymce'
import getPosition from '../getPosition'
import {ARIA_ID_TEMPLATES} from '../../../constants'
import {nanoid} from 'nanoid'
import {handlers, MentionMockUsers} from '../graphql/mswHandlers'
import {mswClient} from '../../../../../../msw/mswClient'
import {mswServer} from '../../../../../../msw/mswServer'
import {ApolloProvider} from 'react-apollo'
import {graphql} from 'msw'

const mockedEditor = {
  editor: {
    id: nanoid()
  }
}

jest.mock('../getPosition')

describe('Mention Dropdown', () => {
  const server = mswServer(handlers)

  beforeAll(() => {
    getPosition.mockImplementation(() => {
      return {top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0}
    })

    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  beforeEach(() => {
    mswClient.cache.reset()
    getPosition.mockClear()
    const editor = new FakeEditor()
    editor.getParam = () => {
      return 'LTR'
    }
    tinymce.activeEditor = editor
  })

  afterEach(() => {
    jest.clearAllMocks()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <MentionDropdown editor={mockedEditor} {...props} />
      </ApolloProvider>
    )
  }

  describe('Rendering', () => {
    it('should render component', () => {
      const component = setup()
      expect(component).toBeTruthy()
    })
  })

  describe('Events', () => {
    it('should attach resize event handler', () => {
      global.addEventListener = jest.fn()
      setup()
      const eventListenerList = global.addEventListener.mock.calls.map(el => {
        return el[0]
      })
      expect(eventListenerList).toContain('resize')
    })

    it('should attach scroll event handler', () => {
      global.addEventListener = jest.fn()
      setup()
      const eventListenerList = global.addEventListener.mock.calls.map(el => {
        return el[0]
      })
      expect(eventListenerList).toContain('scroll')
    })
  })

  describe('Positioning', () => {
    it('should called getXYPosition on load', () => {
      setup()
      expect(getPosition.mock.calls.length).toBe(1)
    })
  })

  describe('Callbacks', () => {
    it('should call onFocusedUserChangeMock when user changes', async () => {
      const onFocusedUserChangeMock = jest.fn()
      const {getAllByTestId} = setup({
        onFocusedUserChange: onFocusedUserChangeMock
      })
      expect(onFocusedUserChangeMock.mock.calls.length).toBe(1)

      const menuItems = await waitFor(() => getAllByTestId('mention-dropdown-item'))
      fireEvent.click(menuItems[3].querySelector('li'))

      // Expect 2 re-renders per click totalling 4
      expect(onFocusedUserChangeMock.mock.calls.length).toBe(4)
    })

    it('should call onSelect when user changes', async () => {
      const onSelectMock = jest.fn()
      const {getAllByTestId} = setup({
        onSelect: onSelectMock
      })

      const menuItems = await waitFor(() => getAllByTestId('mention-dropdown-item'))
      fireEvent.click(menuItems[3].querySelector('li'))

      // Should expect callback to return 1 click
      expect(onSelectMock.mock.calls.length).toBe(1)
    })
  })

  describe('accessibility', () => {
    it('should call ARIA_ID_TEMPLATES and pass to callback', async () => {
      const onActiveDescendantChangeMock = jest.fn()
      const spy = jest.spyOn(ARIA_ID_TEMPLATES, 'activeDescendant')
      const {getAllByTestId} = setup({
        onActiveDescendantChange: onActiveDescendantChangeMock
      })

      const menuItems = await waitFor(() => getAllByTestId('mention-dropdown-item'))
      fireEvent.click(menuItems[1].querySelector('li'))

      expect(spy).toHaveBeenCalled()
    })
  })

  describe('graphql', () => {
    it('should have 10 mentionable users using default handler', async () => {
      const {getAllByTestId} = setup()
      const menuItems = await waitFor(() => getAllByTestId('mention-dropdown-item'))

      expect(menuItems.length).toBe(10)
    })

    it('should have 4 mentionable users using custom handler', async () => {
      server.use(
        graphql.query('GetMentionableUsers', (req, res, ctx) => {
          return res(
            ctx.data({
              legacyNode: {
                id: 'Vxb',
                mentionableUsersConnection: {
                  nodes: MentionMockUsers.slice(0, 4),
                  __typename: 'MessageableUserConnection'
                },
                __typename: 'Discussion'
              }
            })
          )
        })
      )

      const {getAllByTestId} = setup()
      const menuItems = await waitFor(() => getAllByTestId('mention-dropdown-item'))

      expect(menuItems.length).toBe(4)
    })

    it('should render name', async () => {
      const {getByText} = setup()

      expect(await waitFor(() => getByText('Rob Orton'))).toBeTruthy()
      expect(await waitFor(() => getByText('Caleb Guanzon'))).toBeTruthy()
    })
  })
})
