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

import {FocusItemOnSave} from '../index';
import {createAnimation, mockRegistryEntry} from './test-utils';
import {savedPlannerItem} from '../../../actions';

it('sets focus to the saved item', () => {
  const {animation, animator, app, registry} = createAnimation(FocusItemOnSave);
  const mockRegistryEntries = [
    mockRegistryEntry('some-item', 'i1'),
  ];
  app.fixedElementForItemScrolling.mockReturnValue('fixed-element');
  animator.elementPositionMemo.mockReturnValue('position-memo');
  registry.getAllItemsSorted.mockReturnValueOnce(mockRegistryEntries);
  registry.getComponent.mockReturnValueOnce(mockRegistryEntries[0]);
  animation.acceptAction(savedPlannerItem({item: {uniqueId: 'some-item'}}));
  animation.invokeUiWillUpdate();
  animation.invokeUiDidUpdate();
  expect(registry.getComponent).toHaveBeenCalledWith('item', 'some-item');
  expect(animator.maintainViewportPositionFromMemo).toHaveBeenCalledWith('fixed-element', 'position-memo');
  expect(mockRegistryEntries[0].component.getFocusable).toHaveBeenCalledWith('update');
  expect(animator.focusElement).toHaveBeenCalledWith('i1-focusable');
  expect(animator.scrollTo).toHaveBeenCalledWith('i1-scrollable', 34);
});
