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

import {ScrollToNewActivity} from '../scroll-to-new-activity';
import {createAnimation, mockRegistryEntry} from './test-utils';

it('only scrolls when new activity is above the screen', () => {
  const {animation, animator, registry, store} = createAnimation(ScrollToNewActivity);
  const nais = [
    mockRegistryEntry([], 'first'), mockRegistryEntry([], 'second'),
    mockRegistryEntry([], 'third'), mockRegistryEntry([], 'fourth')];
  registry.getAllNewActivityIndicatorsSorted.mockReturnValueOnce(nais);
  animator.isAboveScreen.mockReturnValueOnce(false).mockReturnValue(true);
  animation.uiDidUpdate();
  expect(animator.scrollTo).toHaveBeenCalledWith('third-scrollable', 42);
  expect(animator.scrollToTop).not.toHaveBeenCalled();
  expect(store.dispatch).not.toHaveBeenCalled();
});

describe('new activity requires loading', () => {
  it('scrolls to top and dispatches loadPastUntilNewActivity', () => {
    const {animation, animator, registry, store} = createAnimation(ScrollToNewActivity);
    registry.getAllNewActivityIndicatorsSorted.mockReturnValueOnce([mockRegistryEntry([], 's')]);
    animator.isAboveScreen.mockReturnValueOnce(false);
    animation.uiDidUpdate();
    expect(animator.scrollToTop).toHaveBeenCalled();
    expect(store.dispatch).toHaveBeenCalled();
  });
});
