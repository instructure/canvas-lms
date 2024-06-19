/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Provider} from 'react-redux'
import {shallow} from 'enzyme'
import SearchForm from '../SearchForm'
import SearchResults from '../SearchResults'
import GradebookHistoryApp from '../GradebookHistoryApp'
import GradebookHistoryStore from '../store/GradebookHistoryStore'
import GradebookMenu from '@canvas/gradebook-menu'

const equal = (value, expected) => expect(value).toEqual(expected)
const strictEqual = (value, expected) => expect(value).toBe(expected)

let wrapper

describe('GradebookHistoryApp has component', () => {
  beforeEach(() => {
    wrapper = shallow(<GradebookHistoryApp />)
  })

  afterEach(() => {
    wrapper.unmount()
  })
  test('Provider with a store prop', function () {
    const provider = wrapper.find(Provider)
    equal(provider.length, 1)
    equal(provider.props().store, GradebookHistoryStore)
  })

  test('Heading', function () {
    const heading = wrapper.find('h1')
    strictEqual(heading.length, 1)
  })

  test('SearchForm', function () {
    const form = wrapper.find(SearchForm)
    strictEqual(form.length, 1)
  })

  test('SearchResults', function () {
    const results = wrapper.find(SearchResults)
    strictEqual(results.length, 1)
  })

  describe('GradebookMenu', () => {
    test('is passed the provided courseUrl prop', () => {
      const wrapper = shallow(<GradebookHistoryApp courseUrl="/courseUrl" learningMasteryEnabled />)
      const menu = wrapper.find(GradebookMenu)
      strictEqual(menu.prop('courseUrl'), '/courseUrl')
    })

    test('is passed the provided learningMasteryEnabled prop', () => {
      const wrapper = shallow(
        <GradebookHistoryApp courseUrl="/courseUrl" learningMasteryEnabled={false} />
      )
      const menu = wrapper.find(GradebookMenu)
      strictEqual(menu.prop('learningMasteryEnabled'), false)
    })
  })
})
