/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import {registerScrollEvents} from '../scrollUtils';

function createMockWindow (opts) {
  const callbacks = {};
  return {
    addEventListener: jest.fn((event, callback) => callbacks[event] = callback),
    pageYOffset: 0,
    setTimeout: jest.fn(),
    document: {
      documentElement: {
        clientHeight: 42,
        getBoundingClientRect: () => ({bottom: 42}),
      },
    },
    callbacks,
    ...opts,
  };
}

function mockRegister () {
  const wind = createMockWindow();
  const pastCb = jest.fn();
  const futureCb = jest.fn();
  const scrollPositionChange = jest.fn();
  const callbacks = {};

  registerScrollEvents({
    window: wind,
    scrollIntoPast: pastCb,
    scrollIntoFuture: futureCb,
    scrollPositionChange,
    callbacks,
  });
  return {wind, pastCb, futureCb, scrollPositionChange};
}

it('registers proper events', () => {
  const {wind} = mockRegister();
  expect(wind.addEventListener).toHaveBeenCalledWith('wheel', expect.anything());
  expect(wind.addEventListener).toHaveBeenCalledWith('keydown', expect.anything());
  expect(wind.addEventListener).toHaveBeenCalledWith('touchstart', expect.anything());
  expect(wind.addEventListener).toHaveBeenCalledWith('touchmove', expect.anything());
  expect(wind.addEventListener).toHaveBeenCalledWith('touchend', expect.anything());
});

describe('wheel events', () => {
  describe('scrolling into the past', () => {
    it('invokes the callback and preventDefault when a wheel event happens at the top of the page', () => {
      const {wind, pastCb} = mockRegister();
      const mockPreventDefault = jest.fn();
      const wheelHandler = wind.callbacks.wheel;
      wheelHandler({deltaY: -42, preventDefault: mockPreventDefault});
      expect(mockPreventDefault).toHaveBeenCalled();
      expect(pastCb).toHaveBeenCalled();
    });

    it('does not invoke the callback when the window is not scrolled to the top', () => {
      const {wind, pastCb} = mockRegister();
      wind.pageYOffset = 42;
      const mockPreventDefault = jest.fn();
      const wheelHandler = wind.callbacks.wheel;
      wheelHandler({deltaY: -42, preventDefault: mockPreventDefault});
      expect(mockPreventDefault).not.toHaveBeenCalled();
      expect(pastCb).not.toHaveBeenCalled();
    });
  });

  describe('scrolling into the future', () => {
    it('invokes the callback and preventDefault when a wheel event happens at the bottom of the page', () => {
      const {wind, futureCb} = mockRegister();
      const mockPreventDefault = jest.fn();
      const wheelHandler = wind.callbacks.wheel;
      wheelHandler({deltaY: 42, preventDefault: mockPreventDefault});
      expect(mockPreventDefault).toHaveBeenCalled();
      expect(futureCb).toHaveBeenCalled();
    });

    it('invokes the callback and preventDefault when the document is shorter than the window', () => {
      const {wind, futureCb} = mockRegister();
      wind.document.documentElement.getBoundingClientRect = () => ({bottom: 15});
      const mockPreventDefault = jest.fn();
      const wheelHandler = wind.callbacks.wheel;
      wheelHandler({deltaY: 42, preventDefault: mockPreventDefault});
      expect(mockPreventDefault).toHaveBeenCalled();
      expect(futureCb).toHaveBeenCalled();
    });

    it('does not invoke the callback when the window is not scrolled to the bottom', () => {
      const {wind, futureCb} = mockRegister();
      wind.document.documentElement.getBoundingClientRect = () => ({bottom: 100});
      const mockPreventDefault = jest.fn();
      const wheelHandler = wind.callbacks.wheel;
      wheelHandler({deltaY: 42, preventDefault: mockPreventDefault});
      expect(mockPreventDefault).not.toHaveBeenCalled();
      expect(futureCb).not.toHaveBeenCalled();
    });
  });
});

describe('touch events', () => {
  let mockWindow = null;
  afterEach(() => {
    // need to reset global touch state after each test
    mockWindow.callbacks.touchend({});
  });

  describe('scrolling into the past', () => {
    it('invokes the callback and preventDefault when touch events happen at the top of the page', () => {
      const {wind, pastCb} = mockRegister();
      mockWindow = wind;
      const {touchstart, touchmove} = wind.callbacks;
      touchstart({changedTouches: [{screenY: 10, identifier: 'touchid'}]});
      touchmove({changedTouches: {touchid: {screenY: 14}}});
      expect(pastCb).toHaveBeenCalled();
    });

    it('does not invoke the callback when the window is not scrolled to the top', () => {
      const {wind, pastCb} = mockRegister();
      mockWindow = wind;
      wind.pageYOffset = 42;
      const {touchstart, touchmove} = wind.callbacks;
      touchstart({changedTouches: [{screenY: 10, identifier: 'touchid'}]});
      touchmove({changedTouches: {touchid: {screenY: 14}}});
      expect(pastCb).not.toHaveBeenCalled();
    });

    it('does not invoke the callback when the scroll is not large enough', () => {
      const {wind, pastCb} = mockRegister();
      mockWindow = wind;
      wind.pageYOffset = 42;
      const {touchstart, touchmove} = wind.callbacks;
      touchstart({changedTouches: [{screenY: 10, identifier: 'touchid'}]});
      touchmove({changedTouches: {touchid: {screenY: 13}}});
      expect(pastCb).not.toHaveBeenCalled();
    });
  });

  describe('scrolling into the future', () => {
    it('invokes the callback and preventDefault when touch events happen at the bottom of the page', () => {
      const {wind, futureCb} = mockRegister();
      mockWindow = wind;
      const {touchstart, touchmove} = wind.callbacks;
      touchstart({changedTouches: [{screenY: 10, identifier: 'touchid'}]});
      touchmove({changedTouches: {touchid: {screenY: 6}}});
      expect(futureCb).toHaveBeenCalled();
    });

    it('does not invoke the callback when the window is not scrolled to the bottom', () => {
      const {wind, futureCb} = mockRegister();
      mockWindow = wind;
      const {touchstart, touchmove} = wind.callbacks;
      wind.document.documentElement.getBoundingClientRect = () => ({bottom: 84});
      touchstart({changedTouches: [{screenY: 10, identifier: 'touchid'}]});
      touchmove({changedTouches: {touchid: {screenY: 6}}});
      expect(futureCb).not.toHaveBeenCalled();
    });

    it('does not invoke the callback when the scroll is not large enough', () => {
      const {wind, futureCb} = mockRegister();
      mockWindow = wind;
      const {touchstart, touchmove} = wind.callbacks;
      touchstart({changedTouches: [{screenY: 10, identifier: 'touchid'}]});
      touchmove({changedTouches: {touchid: {screenY: 7}}});
      expect(futureCb).not.toHaveBeenCalled();
    });
  });
});

describe('key events', () => {
  describe('scrolling into the past', () => {
    it('invokes the callback and preventDefault when a key event happens at the top of the page', () => {
      const {wind, pastCb} = mockRegister();
      const mockPreventDefault = jest.fn();
      const keyHandler = wind.callbacks.keydown;
      keyHandler({key: 'ArrowUp', preventDefault: mockPreventDefault});
      expect(mockPreventDefault).toHaveBeenCalled();
      expect(pastCb).toHaveBeenCalled();
    });

    it('does not invoke the past callback or preventDefault on other keys', () => {
      const {wind, pastCb} = mockRegister();
      const mockPreventDefault = jest.fn();
      const keyHandler = wind.callbacks.keydown;
      keyHandler({key: 'Home', preventDefault: mockPreventDefault});
      expect(mockPreventDefault).not.toHaveBeenCalled();
      expect(pastCb).not.toHaveBeenCalled();
    });

    it('does not invoke the past callback if window is not at the top', () => {
      const {wind, pastCb} = mockRegister();
      wind.pageYOffset = 42;
      const mockPreventDefault = jest.fn();
      const keyHandler = wind.callbacks.keydown;
      keyHandler({key: 'ArrowUp', preventDefault: mockPreventDefault});
      expect(mockPreventDefault).not.toHaveBeenCalled();
      expect(pastCb).not.toHaveBeenCalled();
    });
  });

  describe('scrolling into the future', () => {
    it('invokes the future callback and preventDefault when a key event happens at the bottom of the page', () => {
      const {wind, futureCb} = mockRegister();
      const mockPreventDefault = jest.fn();
      const keyHandler = wind.callbacks.keydown;
      keyHandler({key: 'ArrowDown', preventDefault: mockPreventDefault});
      expect(mockPreventDefault).toHaveBeenCalled();
      expect(futureCb).toHaveBeenCalled();
    });

    it('invokes the future callback and preventDefault when a key event happens when the document is shorter than the window', () => {
      const {wind, futureCb} = mockRegister();
      wind.document.documentElement.getBoundingClientRect = () => ({bottom: 24});
      const mockPreventDefault = jest.fn();
      const keyHandler = wind.callbacks.keydown;
      keyHandler({key: 'ArrowDown', preventDefault: mockPreventDefault});
      expect(mockPreventDefault).toHaveBeenCalled();
      expect(futureCb).toHaveBeenCalled();
    });

    it('does not invoke the future callback or preventDefault on other keys', () => {
      const {wind, futureCb} = mockRegister();
      const mockPreventDefault = jest.fn();
      const keyHandler = wind.callbacks.keydown;
      keyHandler({key: 'End', preventDefault: mockPreventDefault});
      expect(mockPreventDefault).not.toHaveBeenCalled();
      expect(futureCb).not.toHaveBeenCalled();
    });

    it('does not invoke the callback if window is not at the bottom', () => {
      const {wind, futureCb} = mockRegister();
      wind.document.documentElement.getBoundingClientRect = () => ({bottom: 100});
      const mockPreventDefault = jest.fn();
      const keyHandler = wind.callbacks.keydown;
      keyHandler({key: 'ArrowDown', preventDefault: mockPreventDefault});
      expect(mockPreventDefault).not.toHaveBeenCalled();
      expect(futureCb).not.toHaveBeenCalled();
    });
  });
});

describe('scroll events', () => {
  it('throttles the callback', () => {
    const mockWindow = createMockWindow();
    const mockScrollCb = jest.fn();
    registerScrollEvents({
      window: mockWindow,
      scrollIntoPast: jest.fn(),
      scrollIntoFuture: jest.fn(),
      scrollPositionChange: mockScrollCb
    });

    mockWindow.pageYOffset = 42;
    mockWindow.callbacks.scroll();
    mockWindow.pageYOffset = 84;
    mockWindow.callbacks.scroll();

    const setTimeoutMock = mockWindow.setTimeout;
    expect(setTimeoutMock).toHaveBeenCalledTimes(1);
    mockWindow.setTimeout.mock.calls[0][0]();
    expect(mockScrollCb).toHaveBeenCalledTimes(1);
    expect(mockScrollCb).toHaveBeenCalledWith(84);
  });
});
