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

import {DynamicUiManager} from '../../manager';

export function mockRegistryEntry (ids, name) {
  return {
    componentIds: ids,
    component: mockComponent(name),
  };
}

export function mockComponent(name) {
  return {
    getFocusable () { return `${name}-focusable`; },
    getScrollable () { return `${name}-scrollable`; },
  };
}

export function mockRegistry () {
  return {
    getLastComponent: jest.fn(),
    getAllNewActivityIndicatorsSorted: jest.fn(),
  };
}

export function mockAnimator () {
  return {
    focusElement: jest.fn(),
    maintainViewportPosition: jest.fn(),
    scrollTo: jest.fn(),
    scrollToTop: jest.fn(),
    isAboveScreen: jest.fn(),
  };
}

export function mockStore () {
  return {
    getState: jest.fn(),
    dispatch: jest.fn(),
  };
}

export function mockManager () {
  return {
    registry: mockRegistry(),
    animator: mockAnimator(),
    store: mockStore(),

    getRegistry () { return this.registry; },
    getAnimator () { return this.animator; },
    getStore () { return this.store; },
    totalOffset () { return 42; },
  };
}

export function createAnimation (AnimationClass) {
  const manager = mockManager();
  const expectedActions = DynamicUiManager.expectedActionsFor(AnimationClass);
  const animation = new AnimationClass(expectedActions, manager);
  return {animation, manager, ...manager};
}
