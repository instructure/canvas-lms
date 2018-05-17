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

import {ReturnFocusOnCancelEditing} from '../index';
import {createAnimation} from './test-utils';
import {openEditingPlannerItem, canceledEditingPlannerItem} from '../../../actions';

function setup (hasPriorFocus = true) {
  const createResult = createAnimation(ReturnFocusOnCancelEditing);
  const {animation, animator, app, document} = createResult;
  app.fixedElementForItemScrolling.mockReturnValue('fixed-element');
  animator.elementPositionMemo.mockReturnValue('fixed-element-memo');
  document.activeElement = hasPriorFocus ? 'prior-focus' : document.body;
  animation.acceptAction(openEditingPlannerItem());
  document.activeElement = 'current-focus';
  animation.acceptAction(canceledEditingPlannerItem());
  return createResult;
}

it('sets focus to the prior focused item', () => {
  const {animation, animator} = setup();
  animation.invokeUiWillUpdate();
  animation.invokeUiDidUpdate();
  // check maintainViewportPosition to work around the chrome bug.
  expect(animator.maintainViewportPositionFromMemo).toHaveBeenCalledWith('fixed-element', 'fixed-element-memo');
  expect(animator.focusElement).toHaveBeenCalledWith('prior-focus');
  expect(animator.scrollTo).toHaveBeenLastCalledWith('prior-focus', 34);
});

it('does not try to scroll to an item in the header', () => {
  const {animation, animator, document} = setup();
  const contains = jest.fn().mockReturnValueOnce(true);
  document.querySelector.mockReturnValueOnce({contains});
  animation.invokeUiWillUpdate();
  animation.invokeUiDidUpdate();
  expect(animator.maintainViewportPositionFromMemo).toHaveBeenCalledWith('fixed-element', 'fixed-element-memo');
  expect(animator.focusElement).toHaveBeenCalledWith('prior-focus');
  expect(contains).toHaveBeenCalledWith('prior-focus');
  expect(animator.scrollTo).not.toHaveBeenCalled();
});

it('does not try to scroll to the document body', () => {
  const {animation, animator} = setup(false);
  animation.invokeUiWillUpdate();
  animation.invokeUiDidUpdate();
  expect(animator.maintainViewportPositionFromMemo).toHaveBeenCalledWith('fixed-element', 'fixed-element-memo');
  expect(animator.focusElement).not.toHaveBeenCalled();
  expect(animator.scrollTo).not.toHaveBeenCalled();
});
