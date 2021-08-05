// /*
//  * Copyright (C) 2021 - present Instructure, Inc.
//  *
//  * This file is part of Canvas.
//  *
//  * Canvas is free software: you can redistribute it and/or modify it under
//  * the terms of the GNU Affero General Public License as published by the Free
//  * Software Foundation, version 3 of the License.
//  *
//  * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
//  * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//  * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
//  * details.
//  *
//  * You should have received a copy of the GNU Affero General Public License along
//  * with this program. If not, see <http://www.gnu.org/licenses/>.
//  */
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import MentionDropdown from '../MentionDropdown'
import FakeEditor from '@instructure/canvas-rce/src/rce/plugins/shared/__tests__/FakeEditor'
import tinymce from 'tinymce'
import getPosition from '../getPosition'

jest.mock('../getPosition')

const setup = props => {
  return render(<MentionDropdown {...props} />)
}

describe('Mention Dropdown', () => {
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
    it('should call onActiveDescendantChange when user changes', () => {
      const onActiveDescendantChangeMock = jest.fn()
      const {getAllByTestId} = setup({
        onActiveDescendantChange: onActiveDescendantChangeMock
      })
      // Each render has this callback fire twice use to how useEffect works
      // with our state
      expect(onActiveDescendantChangeMock.mock.calls.length).toBe(2)

      const menuItems = getAllByTestId('mention-dropdown-item')
      fireEvent.click(menuItems[3].querySelector('li'))

      // Expect 2 re-renders per click totalling 4
      expect(onActiveDescendantChangeMock.mock.calls.length).toBe(4)
    })
  })
})
