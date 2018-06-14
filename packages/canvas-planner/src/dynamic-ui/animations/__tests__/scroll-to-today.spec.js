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
import {initialize} from '../../../utilities/alertUtils';
import {ScrollToToday} from '../scroll-to-today';
import {createAnimation, mockRegistryEntry} from './test-utils';

const TZ = 'Asia/Tokyo';
const successalert = jest.fn();
const pastMessage = 'Nothing planned today. Selecting most recent item.';
const futureMessage = 'Nothing planned today. Selecting next item.';

beforeAll(() => {
  MockDate.set('2018-04-15', TZ);
  initialize({
    visualSuccessCallback: successalert,
    visualErrorCallback: jest.fn(),
    srAlertCallback: jest.fn()
  });
});
afterAll(() => {
  MockDate.reset();
});
beforeEach(() => {
  successalert.mockReset();
});

describe('items are in the planner', () => {
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

  it('focuses on next item if none today', () => {
    const today_elem = {};
    const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday);
    manager.getDocument().querySelector = function () {return today_elem;};
    const mockRegistryEntries = [
      mockRegistryEntry('some-item', 'i1', moment.tz('2018-04-16', TZ)),  // in the future
    ];
    mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem);
    registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries);

    animation.uiDidUpdate();
    expect(successalert).toHaveBeenCalledWith(futureMessage)
    expect(animator.scrollTo).toHaveBeenCalledTimes(2);
    expect(animator.focusElement).toHaveBeenCalledWith('i1-focusable');
  });

  it('focuses on previous item if none today or after', () => {
    const today_elem = {};
    const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday);
    manager.getDocument().querySelector = function () {return today_elem;};
    const mockRegistryEntries = [
      mockRegistryEntry('some-item', 'i1', moment.tz('2018-04-13', TZ)),  // in the past
    ];
    mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem);
    registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries);

    animation.uiDidUpdate();
    expect(successalert).toHaveBeenCalledWith(pastMessage);
    expect(animator.scrollTo).toHaveBeenCalledTimes(2);
    expect(animator.focusElement).toHaveBeenCalledWith('i1-focusable');
  });

  it('focuses on future item even if past item is closer', () => {
    const some_elem = {};
    const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday);
    manager.getDocument().querySelector = function () {return some_elem;};
    const mockRegistryEntries = [
      mockRegistryEntry('past-item', 'p1', moment.tz('2018-04-13', TZ)),  // in the past
      mockRegistryEntry('some-item', 'f1', moment.tz('2018-06-16', TZ)),  // way in the future
    ];
    mockRegistryEntries[0].component.getScrollable.mockReturnValue(some_elem);
    mockRegistryEntries[1].component.getScrollable.mockReturnValue(some_elem);
    registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries);

    animation.uiDidUpdate();
    expect(successalert).toHaveBeenCalledWith(futureMessage)
    expect(animator.scrollTo).toHaveBeenCalledTimes(2);
    expect(animator.focusElement).toHaveBeenCalledWith('f1-focusable');
  });

  it('ignores items w/o a date', () => {
    successalert.mockReset();
    const some_elem = {};
    const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday);
    manager.getDocument().querySelector = function () {return some_elem;};
    const mockRegistryEntries = [
      mockRegistryEntry('past-item', 'p1', moment.tz('2018-04-13', TZ)),  // in the past
      mockRegistryEntry('some-item', 'f1', undefined),
    ];
    mockRegistryEntries[0].component.getScrollable.mockReturnValue(some_elem);
    mockRegistryEntries[1].component.getScrollable.mockReturnValue(some_elem);
    registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries);

    animation.uiDidUpdate();
    expect(successalert).toHaveBeenCalledWith(pastMessage)
    expect(animator.scrollTo).toHaveBeenCalledTimes(2);
    expect(animator.focusElement).toHaveBeenCalledWith('p1-focusable');
  });

});

describe('items require loading', () => {
  it('scrolls to top and dispatches loadPastUntilToday', () => {
    const {animation, animator, store} = createAnimation(ScrollToToday);

    animation.uiDidUpdate();
    expect(animator.scrollToTop).toHaveBeenCalled();
    expect(store.dispatch).toHaveBeenCalled();
  });
});
