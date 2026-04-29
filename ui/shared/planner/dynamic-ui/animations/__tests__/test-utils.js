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

import {DynamicUiManager} from '../../manager'

export function mockRegistryEntry(ids, name, date) {
  return {
    componentIds: ids,
    component: mockComponent(name, date),
  }
}

export function mockApp() {
  return {
    fixedElementForItemScrolling: vi.fn(),
  }
}

export function mockDocument() {
  return {
    activeElement: 'active-element',
    querySelector: vi.fn(),
    getElementById: vi.fn(),
    body: {},
  }
}

export function mockComponent(name, date) {
  return {
    uniqueId: 'unique-id',
    getFocusable: vi.fn(() => `${name}-focusable`),
    getScrollable: vi.fn(() => `${name}-scrollable`),
    props: {
      associated_item: 'Assignment',
      courseName: 'Course X',
      date,
      title: name,
    },
  }
}

export function mockRegistry() {
  return {
    getComponent: vi.fn(),
    getLastComponent: vi.fn(),
    getAllNewActivityIndicatorsSorted: vi.fn(),
    getAllItemsSorted: vi.fn(),
  }
}

export function mockAnimator() {
  return {
    getWindow: vi.fn(() => window),
    focusElement: vi.fn(),
    elementPositionMemo: vi.fn(),
    maintainViewportPositionFromMemo: vi.fn(),
    scrollTo: vi.fn((scrollable, offset, callback) => {
      callback && callback()
    }),
    forceScrollTo: vi.fn((scrollable, offset, callback) => {
      callback && callback()
    }),
    scrollToTop: vi.fn(),
    isAboveScreen: vi.fn(),
    isBelowScreen: vi.fn(),
    isOnScreen: vi.fn(),
    isOffScreen: vi.fn(),
  }
}

export function mockStore() {
  return {
    getState: vi.fn(),
    dispatch: vi.fn(),
  }
}

export function mockManager() {
  return {
    registry: mockRegistry(),
    animator: mockAnimator(),
    store: mockStore(),
    app: mockApp(),
    document: mockDocument(),

    getRegistry() {
      return this.registry
    },
    getAnimator() {
      return this.animator
    },
    getStore() {
      return this.store
    },
    getApp() {
      return this.app
    },
    getDocument() {
      return this.document
    },
    getStickyOffset() {
      return 34
    },
    totalOffset() {
      return 42
    },
  }
}

export function createAnimation(AnimationClass) {
  const manager = mockManager()
  const expectedActions = DynamicUiManager.expectedActionsFor(AnimationClass)
  const animation = new AnimationClass(expectedActions, manager)
  return {animation, manager, ...manager}
}
