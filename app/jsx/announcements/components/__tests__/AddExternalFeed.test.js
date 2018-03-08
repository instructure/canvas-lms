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

import '@instructure/ui-themes/lib/canvas'
import React from 'react'
import {shallow} from 'enzyme'
import AddExternalFeed from '../AddExternalFeed'

const defaultProps = () => ({
  defaultOpen: false,
  isSaving: false,
  addExternalFeed: () => {}
})

test('renders the AddExternalFeed component', () => {
  const tree = shallow(<AddExternalFeed {...defaultProps()} />)
  expect(tree.exists()).toBe(true)
})

test('does not render the AddExternalFeed Tray when closed', () => {
  const tree = shallow(<AddExternalFeed {...defaultProps()} />)
  const node = tree.find('#external-rss-feed__cancel-button')
  expect(node.exists()).toBe(false)
})

test('renders the AddExternalFeed submit buttons when open', () => {
  const props = defaultProps()
  props.defaultOpen = true
  const tree = shallow(<AddExternalFeed {...props} />)
  const node = tree.find('Button')
  expect(node.exists()).toBe(true)
})

test('closes the AddExternalFeed when cancel pressed', () => {
  const props = defaultProps()
  props.defaultOpen = true
  const tree = shallow(<AddExternalFeed {...props} />)
  tree.instance().clearAddRSS()
  expect(tree.state().isOpen).toBe(false)
})

test('submits the AddExternalFeed with correct arguments', () => {
  const props = defaultProps()
  const addFeedSpy = jest.fn()
  props.addExternalFeed = addFeedSpy
  const tree = shallow(<AddExternalFeed {...props} />)
  tree.instance().handleCheckboxPhraseChecked({
    target: {
      checked: true
    }
  })
  tree.instance().handleTextInputSetPhrase({
    target: {
      value: 'phrase'
    }
  })
  tree.instance().handleTextInputSetFeedURL({
    target: {
      value: 'url'
    }
  })
  tree.instance().handleRadioSelectionSetVerbosity('full')
  tree.instance().addRssSelection()
  expect(addFeedSpy.mock.calls[0][0]).toMatchObject({
    header_match: 'phrase',
    url: 'url',
    verbosity: 'full'
  })
})

test('isDoneSelecting correctly returns true when all arguments are set', () => {
  const props = defaultProps()
  const addFeedSpy = jest.fn()
  props.addExternalFeed = addFeedSpy
  const tree = shallow(<AddExternalFeed {...props} />)
  tree.instance().handleCheckboxPhraseChecked({
    target: {
      checked: true
    }
  })
  tree.instance().handleTextInputSetPhrase({
    target: {
      value: 'phrase'
    }
  })
  tree.instance().handleTextInputSetFeedURL({
    target: {
      value: 'url'
    }
  })
  tree.instance().handleRadioSelectionSetVerbosity('full')
  expect(tree.instance().isDoneSelecting()).toBe(true)
})

test('isDoneSelecting correctly returns false when all url is missing', () => {
  const props = defaultProps()
  const addFeedSpy = jest.fn()
  props.addExternalFeed = addFeedSpy
  const tree = shallow(<AddExternalFeed {...props} />)
  tree.instance().handleRadioSelectionSetVerbosity('full')
  tree.instance().handleTextInputSetFeedURL({
    target: {
      value: null
    }
  })
  expect(tree.instance().isDoneSelecting()).toBe(false)
})

test('isDoneSelecting correctly returns false when all phrase is missing', () => {
  const props = defaultProps()
  const addFeedSpy = jest.fn()
  props.addExternalFeed = addFeedSpy
  const tree = shallow(<AddExternalFeed {...props} />)
  tree.instance().handleCheckboxPhraseChecked({
    target: {
      checked: true
    }
  })
  tree.instance().handleRadioSelectionSetVerbosity('full')
  expect(tree.instance().isDoneSelecting()).toBe(false)
})
