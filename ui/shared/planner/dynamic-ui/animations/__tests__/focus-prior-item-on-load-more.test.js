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

import {FocusPriorItemOnLoadMore} from '../focus-prior-item-on-load-more'
import {createAnimation, mockRegistryEntry} from './test-utils'
import {gettingFutureItems, gotDaysSuccess} from '../../../actions/loading-actions'

function createReadyAnimation() {
  const result = createAnimation(FocusPriorItemOnLoadMore)
  result.animation.acceptAction(gettingFutureItems({loadMoreButtonClicked: true}))
  result.animation.acceptAction(
    gotDaysSuccess([['2018-03-28', [{uniqueId: 'new-item-1'}, {uniqueId: 'new-item-2'}]]])
  )
  return result
}

afterEach(() => jest.resetAllMocks())

it('only accepts GETTING_FUTURE_ITEMS if it came from the load more button', () => {
  const {animation} = createAnimation(FocusPriorItemOnLoadMore)
  expect(animation.acceptAction(gettingFutureItems({loadMoreButtonClicked: false}))).toBe(false)
  expect(animation.acceptAction(gettingFutureItems({loadMoreButtonClicked: true}))).toBe(true)
})

it('sets focus to the last existing item before the load', () => {
  const {animation, registry, animator} = createReadyAnimation()
  const mockRegistryEntries = [
    mockRegistryEntry(['existing-item-1'], 'e1'),
    mockRegistryEntry(['existing-item-2'], 'e2'),
    mockRegistryEntry(['new-item-1'], 'n1'),
    mockRegistryEntry(['new-item-2'], 'n2'),
  ]
  registry.getAllItemsSorted.mockReturnValueOnce(mockRegistryEntries)
  animation.uiDidUpdate()
  expect(animator.focusElement).toHaveBeenCalledWith('e2-focusable')
})

it('logs an error if there is no previous item to set focus to', () => {
  const consoleError = jest.spyOn(global.console, 'error')
  consoleError.mockImplementation(() => {}) // keep it from actually logging
  const {animation, registry, animator} = createReadyAnimation()
  const mockRegistryEntries = [
    mockRegistryEntry(['new-item-1'], 'e1'),
    mockRegistryEntry(['new-item-2'], 'e2'),
  ]
  registry.getAllItemsSorted.mockReturnValueOnce(mockRegistryEntries)
  animation.uiDidUpdate()
  expect(consoleError).toHaveBeenCalled()
  expect(animator.focusElement).not.toHaveBeenCalled()
})
