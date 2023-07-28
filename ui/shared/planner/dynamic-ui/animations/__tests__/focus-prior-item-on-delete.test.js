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

import {FocusPriorItemOnDelete} from '../index'
import {createAnimation, mockRegistryEntry} from './test-utils'
import {deletedPlannerItem} from '../../../actions'
import {specialFallbackFocusId} from '../../util'

// it uses a timer to work around an inst ui bug. See code in uiDidUpdate
jest.useFakeTimers()
function prepareAnimation(animation) {
  animation.acceptAction(deletedPlannerItem({uniqueId: 'doomed-item'}))
  animation.uiWillUpdate()
  animation.uiDidUpdate()
  jest.runAllTimers()
}

it('sets focus to the item prior to the deleted item', () => {
  const {animation, registry, animator} = createAnimation(FocusPriorItemOnDelete)
  const mockRegistryEntries = [
    mockRegistryEntry(['prior-item-1'], 'p1'),
    mockRegistryEntry(['prior-item-2'], 'p2'),
    mockRegistryEntry(['doomed-item'], 'd1'),
    mockRegistryEntry(['next-item-1'], 'n1'),
  ]
  registry.getAllItemsSorted.mockReturnValueOnce(mockRegistryEntries)
  registry.getComponent.mockReturnValueOnce(mockRegistryEntries[1])
  prepareAnimation(animation)
  expect(registry.getComponent).toHaveBeenCalledWith('item', 'prior-item-2')
  expect(animator.focusElement).toHaveBeenCalledWith('p2-focusable')
  expect(animator.scrollTo).toHaveBeenCalledWith('p2-scrollable', 34)
})

it('sets focus to the fallback item focus if deleted index is 0', () => {
  const {animation, registry, animator} = createAnimation(FocusPriorItemOnDelete)
  const mockRegistryEntries = [
    mockRegistryEntry(['doomed-item'], 'd1'),
    mockRegistryEntry(['next-item-1'], 'n1'),
  ]
  registry.getAllItemsSorted.mockReturnValueOnce(mockRegistryEntries)
  registry.getComponent.mockReturnValueOnce(
    mockRegistryEntry([specialFallbackFocusId('item')], 'fb')
  )
  prepareAnimation(animation)
  expect(registry.getComponent).toHaveBeenCalledWith('item', specialFallbackFocusId('item'))
  expect(animator.focusElement).toHaveBeenCalledWith('fb-focusable')
  expect(animator.scrollTo).toHaveBeenCalledWith('fb-scrollable', 34)
})

it('gives up without borking if there is no fallback', () => {
  const {animation, registry, animator} = createAnimation(FocusPriorItemOnDelete)
  const mockRegistryEntries = [
    mockRegistryEntry(['doomed-item'], 'd1'),
    mockRegistryEntry(['next-item-1'], 'n1'),
  ]
  registry.getAllItemsSorted.mockReturnValueOnce(mockRegistryEntries)
  prepareAnimation(animation)
  expect(registry.getComponent).toHaveBeenCalledWith('item', specialFallbackFocusId('item'))
  expect(animator.focusElement).not.toHaveBeenCalled()
  expect(animator.scrollTo).not.toHaveBeenCalled()
})
