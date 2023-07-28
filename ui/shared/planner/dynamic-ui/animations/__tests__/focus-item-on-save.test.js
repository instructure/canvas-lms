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

import {FocusItemOnSave} from '../index'
import {createAnimation, mockRegistryEntry} from './test-utils'
import {savedPlannerItem} from '../../../actions'
import {initialize as alertInitialize} from '../../../utilities/alertUtils'

let alertMocks = null

beforeEach(() => {
  alertMocks = {
    visualSuccessCallback: jest.fn(),
    visualErrorCallback: jest.fn(),
    srAlertCallback: jest.fn(),
  }
  alertInitialize(alertMocks)
})

function createMockFixture() {
  const createResult = createAnimation(FocusItemOnSave)
  const {animator, app, registry} = createResult
  const mockRegistryEntries = [mockRegistryEntry('some-item', 'i1')]
  app.fixedElementForItemScrolling.mockReturnValue('fixed-element')
  animator.elementPositionMemo.mockReturnValue('position-memo')
  registry.getAllItemsSorted.mockReturnValueOnce(mockRegistryEntries)
  registry.getComponent.mockReturnValueOnce(mockRegistryEntries[0])
  return {...createResult, mockRegistryEntries}
}

it('sets focus to the saved item', () => {
  const {animation, animator, registry, mockRegistryEntries} = createMockFixture()
  animation.acceptAction(savedPlannerItem({item: {uniqueId: 'some-item'}}))
  animation.invokeUiWillUpdate()
  animation.invokeUiDidUpdate()
  expect(registry.getComponent).toHaveBeenCalledWith('item', 'some-item')
  expect(animator.maintainViewportPositionFromMemo).toHaveBeenCalledWith(
    'fixed-element',
    'position-memo'
  )
  expect(mockRegistryEntries[0].component.getFocusable).toHaveBeenCalledWith('update')
  expect(animator.focusElement).toHaveBeenCalledWith('i1-focusable')
  expect(animator.scrollTo).toHaveBeenCalledWith('i1-scrollable', 34)
})

it('leaves focus alone (on the checkbox) if the item was toggled', () => {
  const {animation, animator} = createMockFixture()
  animation.acceptAction(savedPlannerItem({wasToggled: true, item: {uniqueId: 'some-item'}}))
  animation.invokeUiWillUpdate()
  animation.invokeUiDidUpdate()
  expect(animator.focusElement).not.toHaveBeenCalled()
  expect(animator.maintainViewportPositionFromMemo).toHaveBeenCalledWith(
    'fixed-element',
    'position-memo'
  )
  expect(animator.scrollTo).toHaveBeenCalledWith('i1-scrollable', 34)
})

it('alerts if the saved item is not loaded', () => {
  const {animation, animator} = createAnimation(FocusItemOnSave)
  animation.acceptAction(savedPlannerItem({item: {uniqueId: 'out-of-loaded-range-item'}}))
  animation.invokeUiWillUpdate()
  animation.invokeUiDidUpdate()
  expect(alertMocks.visualSuccessCallback).toHaveBeenCalled()
  expect(animator.focusElement).not.toHaveBeenCalled()
})
