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

import MockDate from 'mockdate';
import moment from 'moment-timezone';
import {ScrollToToday} from '../scroll-to-today';
import {createAnimation, mockRegistryEntry} from './test-utils';

const TZ = 'Asia/Tokyo';

beforeAll(() => {
  MockDate.set('2018-04-15', TZ);
});
afterAll(() => {
  MockDate.reset();
});

it('scrolls when today is in the DOM', () => {
  const today_elem = {};
  const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday);
  manager.getDocument().querySelector = function () {return today_elem;};
  const mockRegistryEntries = [
    mockRegistryEntry('some-item', 'i1', moment.tz(TZ)),
  ];
  mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem);
  registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries);

  animation.uiDidUpdate();
  expect(animator.scrollTo.mock.calls[0][0]).toEqual(today_elem);
  expect(animator.scrollToTop).not.toHaveBeenCalled();
  expect(store.dispatch).not.toHaveBeenCalled();
});

it('scrolls to the top when it cannot find today', () => {
  const {animation, animator, registry} = createAnimation(ScrollToToday);
  const mockRegistryEntries = [
    mockRegistryEntry('some-item', 'i1', moment.tz(TZ)),
  ];
  registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries);

  animation.uiDidUpdate();
  expect(animator.scrollTo).not.toHaveBeenCalled();
  expect(animator.scrollToTop).toHaveBeenCalled();
});

describe('items require requires loading', () => {
  it('scrolls to top and dispatches loadPastUntilToday', () => {
    const {animation, animator, store} = createAnimation(ScrollToToday);

    animation.uiDidUpdate();
    expect(animator.scrollToTop).toHaveBeenCalled();
    expect(store.dispatch).toHaveBeenCalled();
  });
});
