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

import {ScrollToLastLoadedNewActivity} from '../scroll-to-last-loaded-new-activity'
import {createAnimation, mockRegistryEntry} from './test-utils'
import {
  startLoadingPastUntilNewActivitySaga,
  gotDaysSuccess,
} from '../../../actions/loading-actions'

function createReadyAnimation(withNa = true) {
  const result = createAnimation(ScrollToLastLoadedNewActivity)
  result.animation.acceptAction(startLoadingPastUntilNewActivitySaga())
  result.animation.acceptAction(
    gotDaysSuccess([
      [
        '2018-03-19',
        [
          {uniqueId: 'item-1'},
          {uniqueId: 'item-2', newActivity: withNa},
          {uniqueId: 'item-3', newActivity: withNa},
          {uniqueId: 'item-4'},
        ],
      ],
    ])
  )
  return result
}

it('scrolls to the last newly loaded item with new activity', () => {
  const {animation, registry, app, animator} = createReadyAnimation()
  const mockDayEntry = mockRegistryEntry(['item-1', 'item-2', 'item-3', 'item-4'])
  const mockNaiEntry = mockRegistryEntry(['item-3'], 'nai')
  registry.getLastComponent.mockReturnValueOnce(mockDayEntry).mockReturnValueOnce(mockNaiEntry)
  app.fixedElementForItemScrolling.mockReturnValue('fixed-element')
  animator.elementPositionMemo.mockReturnValueOnce('position-memo')
  animation.invokeUiWillUpdate()
  animation.invokeUiDidUpdate()

  expect(registry.getLastComponent).toHaveBeenCalledWith(
    'day',
    expect.objectContaining(['item-2', 'item-3'])
  )
  expect(registry.getLastComponent).toHaveBeenCalledWith(
    'new-activity-indicator',
    expect.objectContaining(['item-2', 'item-3'])
  )

  expect(animator.maintainViewportPositionFromMemo).toHaveBeenCalledWith(
    'fixed-element',
    'position-memo'
  )
  expect(animator.scrollTo).toHaveBeenCalledWith('nai-scrollable', 42)
  expect(animator.focusElement).toHaveBeenCalledWith('nai-focusable')
})

it('does nothing if there is no new activity on load', () => {
  const {animation, animator} = createReadyAnimation(false)
  animation.invokeUiWillUpdate()
  animation.invokeUiDidUpdate()
  expect(animator.scrollTo).not.toHaveBeenCalled()
  expect(animator.focusElement).not.toHaveBeenCalled()
})
