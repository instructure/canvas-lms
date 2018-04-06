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

import {Animator} from '../animator';

function mockVelocity (opts = {}) {
  return jest.fn();
}

function mockElement (opts = {}) {
  return {
    getBoundingClientRect: jest.fn(),
    focus: jest.fn(),
    ...opts
  };
}

function mockWindow (opts = {}) {
  const queue = [];
  return {
    queue,
    innerHeight: 100,
    scroll: jest.fn(),
    requestAnimationFrame: (fn) => queue.push(fn),
    runAnimationFrames: () => {
      queue.forEach((fn) => fn());
      queue.length = 0;
    },
  };
}

function mockDocument (opts = {}) {
  return {
    documentElement: opts.documentElement || {
      getBoundingClientRect: jest.fn(),
    }
  };
}

function makeAnimator (opts = {}) {
  const mocks = {
    velocity: mockVelocity(opts),
    window: mockWindow(opts),
    document: mockDocument(opts),
    ...opts,
  };
  const animator = new Animator(mocks);
  return { animator, mocks };
}

it('focuses elements', () => {
  const {animator, mocks} = makeAnimator();
  const elt = mockElement();
  animator.focusElement(elt);
  expect(elt.focus).not.toHaveBeenCalled();
  mocks.window.runAnimationFrames();
  expect(elt.focus).toHaveBeenCalled();
});

it('scrolls to elements with that are below the viewport', () => {
  const {animator, mocks} = makeAnimator();
  const elt = mockElement();
  elt.getBoundingClientRect.mockReturnValueOnce({top: 95, left: 0, bottom: 105, right: 42});
  animator.scrollTo(elt, 5);
  expect(mocks.velocity).not.toHaveBeenCalled();
  mocks.window.runAnimationFrames();
  expect(mocks.velocity).toHaveBeenCalledWith(elt, 'scroll', expect.objectContaining({offset: -5}));
});

it('scrolls to elements that are above the offset', () => {
  const {animator, mocks} = makeAnimator();
  const elt = mockElement();
  elt.getBoundingClientRect.mockReturnValueOnce({top: 4, left: 0, bottom: 20, right: 42});
  animator.scrollTo(elt, 5);
  mocks.window.runAnimationFrames();
  expect(mocks.velocity).toHaveBeenCalledWith(elt, 'scroll', expect.objectContaining({offset: -5}));
});

it('does not scroll to element if it is already fully in view', () => {
  const {animator, mocks} = makeAnimator();
  const elt = mockElement();
  elt.getBoundingClientRect.mockReturnValue({top: 5, left: 0, bottom: 95, right: 42});
  animator.scrollTo(elt, 5);
  mocks.window.runAnimationFrames();
  expect(mocks.velocity).not.toHaveBeenCalled();
});

it('maintains scroll position of element', () => {
  const {animator, mocks} = makeAnimator();
  const elt = mockElement();
  elt.getBoundingClientRect
    .mockReturnValueOnce({top: 42, left: 0, bottom: 43, right: 42})
    .mockReturnValueOnce({top: 52, left: 0, bottom: 53, right: 42});
  mocks.document.documentElement.getBoundingClientRect.mockReturnValueOnce({
    top: -5, left: 0, bottom: 123, right: 50,
  });
  const fixedMemo = animator.elementPositionMemo(elt);
  animator.maintainViewportPositionFromMemo(elt, fixedMemo);
  expect(mocks.window.scroll).not.toHaveBeenCalled();
  mocks.window.runAnimationFrames();
  // 15 = 52 - (-5) - 42
  expect(mocks.window.scroll).toHaveBeenCalledWith(0, 15);
});

it('does focus action before other operations', () => {
  const {animator, mocks} = makeAnimator();
  const elt = mockElement();
  elt.getBoundingClientRect.mockReturnValue({top: 10, left: 0, bottom: 20, right: 42});
  animator.scrollTo(elt, 42);
  animator.focusElement(elt);
  expect(mocks.window.queue.length).toBe(2);
  expect(elt.focus).not.toHaveBeenCalled();
  mocks.window.queue[0]();
  expect(elt.focus).toHaveBeenCalled();
  expect(mocks.window.scroll).not.toHaveBeenCalled();
  mocks.window.queue[1]();
  expect(mocks.velocity).toHaveBeenCalledWith(elt, 'scroll', expect.anything());
});

it('determines when an element is on or below the screen', () => {
  const {animator} = makeAnimator();
  const elt = mockElement();
  elt.getBoundingClientRect.mockReturnValue({top: 42});
  expect(animator.isAboveScreen(elt, 42)).toBe(false);
});

it('determines when an element is above the screen', () => {
  const {animator} = makeAnimator();
  const elt = mockElement();
  elt.getBoundingClientRect.mockReturnValue({top: 41});
  expect(animator.isAboveScreen(elt, 42)).toBe(true);
});
