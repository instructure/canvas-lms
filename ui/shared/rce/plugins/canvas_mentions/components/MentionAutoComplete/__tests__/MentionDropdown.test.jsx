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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import MentionDropdown from '../MentionDropdown'
import FakeEditor from '../../../__tests__/FakeEditor'
import tinymce from 'tinymce'
import getPosition from '../getPosition'
import {ARIA_ID_TEMPLATES} from '../../../constants'
import {nanoid} from 'nanoid'

const mockedEditor = {
  editor: {
    id: nanoid(),
  },
}

jest.mock('../getPosition')

jest.mock('@apollo/react-hooks', () => {
  const data = {
    legacyNode: {
      id: 'Vxb',
      mentionableUsersConnection: {
        nodes: [
          {
            _id: 'Aa',
            id: 1,
            name: 'Jeffrey Johnson',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Ab',
            id: 2,
            name: 'Matthew Lemon',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Ac',
            id: 3,
            name: 'Rob Orton',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Ad',
            id: 4,
            name: 'Davis Hyer',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Ae',
            id: 5,
            name: 'Drake Harper',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Af',
            id: 6,
            name: 'Omar Soto-Fortuño',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Ag',
            id: 7,
            name: 'Chawn Neal',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Ah',
            id: 8,
            name: 'Mauricio Ribeiro',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Ai',
            id: 9,
            name: 'Caleb Guanzon',
            __typename: 'MessageableUser',
          },
          {
            _id: 'Aj',
            id: 10,
            name: 'Jason Gillett',
            __typename: 'MessageableUser',
          },
        ],
        __typename: 'MessageableUserConnection',
      },
      __typename: 'Discussion',
    },
  }

  return {
    __esModule: true,
    useQuery: () => ({data}),
  }
})

describe('Mention Dropdown', () => {
  beforeAll(() => {
    getPosition.mockImplementation(() => {
      return {top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0}
    })
  })

  beforeEach(() => {
    getPosition.mockClear()
    const editor = new FakeEditor()
    editor.getParam = () => {
      return 'LTR'
    }
    tinymce.activeEditor = editor
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const setup = props => {
    return render(<MentionDropdown editor={mockedEditor} rceRef={document.body} {...props} />)
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
    it('should call onFocusedUserChangeMock when user changes', () => {
      const onFocusedUserChangeMock = jest.fn()
      const {getAllByTestId} = setup({
        onFocusedUserChange: onFocusedUserChangeMock,
      })

      // This number is always double menu count as two menus exist in the same dom
      expect(getAllByTestId('mention-dropdown-item').length).toBe(20)

      expect(onFocusedUserChangeMock.mock.calls.length).toBe(1)

      const menuItems = getAllByTestId('mention-dropdown-item')
      fireEvent.click(menuItems[3].querySelector('li'))

      // Expect 1 re-renders per click totalling 2
      expect(onFocusedUserChangeMock.mock.calls.length).toBe(2)
    })
  })

  describe('accessibility', () => {
    it('should call ARIA_ID_TEMPLATES and pass to callback', async () => {
      const onActiveDescendantChangeMock = jest.fn()
      const spy = jest.spyOn(ARIA_ID_TEMPLATES, 'activeDescendant')
      const {getAllByTestId} = setup({
        onActiveDescendantChange: onActiveDescendantChangeMock,
      })

      // This number is always double menu count as two menus exist in the same dom
      expect(getAllByTestId('mention-dropdown-item').length).toBe(20)

      const menuItems = getAllByTestId('mention-dropdown-item')
      fireEvent.click(menuItems[1].querySelector('li'))

      expect(spy).toHaveBeenCalled()
    })
  })
})
