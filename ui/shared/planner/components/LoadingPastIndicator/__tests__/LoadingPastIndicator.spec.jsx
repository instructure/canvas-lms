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
import {shallow} from 'enzyme'
import LoadingPastIndicator from '../index'

jest.mock('../../../utilities/scrollUtils')

it('renders very little', () => {
  const wrapper = shallow(<LoadingPastIndicator />)
  expect(wrapper).toMatchSnapshot()
})

it('renders spinner while loading', () => {
  const wrapper = shallow(<LoadingPastIndicator loadingPast />)
  expect(wrapper).toMatchSnapshot()
})

it('prioritizes loading complete over currently loading', () => {
  const wrapper = shallow(<LoadingPastIndicator loadingPast allPastItemsLoaded />)
  expect(wrapper).toMatchSnapshot()
})

it('renders TV when all past items loaded', () => {
  const wrapper = shallow(<LoadingPastIndicator allPastItemsLoaded />)
  expect(wrapper).toMatchSnapshot()
})

it("shows an Alert when there's a query error", () => {
  const wrapper = shallow(<LoadingPastIndicator loadingError="uh oh" />)
  expect(wrapper).toMatchSnapshot()
})
