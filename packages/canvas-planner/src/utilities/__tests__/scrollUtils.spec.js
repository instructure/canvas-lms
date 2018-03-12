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
  return {
    addEventListener: jest.fn(),
    pageYOffset: 0,
    setTimeout: jest.fn(),
    ...opts,
  };
}

it('registers proper events', () => {
  const mockWindow = createMockWindow();
  registerScrollEvents(jest.fn, jest.fn(), mockWindow);
  expect(mockWindow.addEventListener.mock.calls[0][0]).toBe('wheel');
  expect(mockWindow.addEventListener.mock.calls[1][0]).toBe('keydown');
});

describe('wheel events', () => {
  it('invokes the callback and preventDefault when a wheel event happens at the top of the page', () => {
    const mockWindow = createMockWindow();
    const mockCb = jest.fn();
    const mockPreventDefault = jest.fn();
    registerScrollEvents(mockCb, jest.fn(), mockWindow);
    const wheelHandler = mockWindow.addEventListener.mock.calls[0][1];
    wheelHandler({deltaY: -42, preventDefault: mockPreventDefault});
    expect(mockPreventDefault).toHaveBeenCalled();
    expect(mockCb).toHaveBeenCalled();
  });

  it('does not invoke the callback when the window is not scrolled to the top', () => {
    const mockWindow = createMockWindow({ pageYOffset: 42 });
    const mockCb = jest.fn();
    const mockPreventDefault = jest.fn();
    registerScrollEvents(mockCb, jest.fn(), mockWindow);
    const wheelHandler = mockWindow.addEventListener.mock.calls[0][1];
    wheelHandler({deltaY: -42, preventDefault: mockPreventDefault});
    expect(mockPreventDefault).not.toHaveBeenCalled();
    expect(mockCb).not.toHaveBeenCalled();
  });
});

describe('key events', () => {
  it('invokes the callback and preventDefault when a wheel event happens at the top of the page', () => {
    const mockWindow = createMockWindow();
    const mockCb = jest.fn();
    const mockPreventDefault = jest.fn();
    registerScrollEvents(mockCb, jest.fn(), mockWindow);
    const keyHandler = mockWindow.addEventListener.mock.calls[1][1];
    keyHandler({key: 'ArrowUp', preventDefault: mockPreventDefault});
    expect(mockPreventDefault).toHaveBeenCalled();
    expect(mockCb).toHaveBeenCalled();
  });

  it('does not invoke the callback or preventDefault on other keys', () => {
    const mockWindow = createMockWindow();
    const mockCb = jest.fn();
    const mockPreventDefault = jest.fn();
    registerScrollEvents(mockCb, jest.fn(), mockWindow);
    const keyHandler = mockWindow.addEventListener.mock.calls[1][1];
    keyHandler({key: 'Home', preventDefault: mockPreventDefault});
    expect(mockPreventDefault).not.toHaveBeenCalled();
    expect(mockCb).not.toHaveBeenCalled();
  });

  it('does not invoke the callback if window is not at the top', () => {
    const mockWindow = createMockWindow({ pageYOffset: 42 });
    const mockCb = jest.fn();
    const mockPreventDefault = jest.fn();
    registerScrollEvents(mockCb, jest.fn(), mockWindow);
    const keyHandler = mockWindow.addEventListener.mock.calls[1][1];
    keyHandler({key: 'ArrowUp', preventDefault: mockPreventDefault});
    expect(mockPreventDefault).not.toHaveBeenCalled();
    expect(mockCb).not.toHaveBeenCalled();
  });
});

describe('scroll events', () => {
  it('throttles the callback', () => {
    const mockWindow = createMockWindow();
    mockWindow.addEventListener = (event, cb) => {
      if (event === 'scroll') { mockWindow.registeredScrollHandler = cb; }
    };
    const mockScrollCb = jest.fn();
    registerScrollEvents(jest.fn(), mockScrollCb, mockWindow);

    mockWindow.pageYOffset = 42;
    mockWindow.registeredScrollHandler();
    mockWindow.pageYOffset = 84;
    mockWindow.registeredScrollHandler();

    const setTimeoutMock = mockWindow.setTimeout;
    expect(setTimeoutMock).toHaveBeenCalledTimes(1);
    mockWindow.setTimeout.mock.calls[0][0]();
    expect(mockScrollCb).toHaveBeenCalledTimes(1);
    expect(mockScrollCb).toHaveBeenCalledWith(84);
  });
});
