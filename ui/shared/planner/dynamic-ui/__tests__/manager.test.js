/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {DynamicUiManager as Manager} from '../manager'
import {specialFallbackFocusId} from '../util'
import {dismissedOpportunity, setNaiAboveScreen} from '../../actions'
import {
  startLoadingItems,
  gettingFutureItems,
  gettingPastItems,
  gotItemsSuccess,
  startLoadingGradesSaga,
  gotGradesSuccess,
} from '../../actions/loading-actions'
import {initialize as alertInitialize} from '../../utilities/alertUtils'

const plannerHeaderId = 'headerid'
const newActivityId = 'newactivityid'

class MockAnimator {
  animationOrder = []

  isAboveScreen = jest.fn()

  recordFixedElement = jest.fn()

  constructor() {
    ;['focusElement'].forEach(fnName => {
      this[fnName] = jest.fn(() => {
        this.animationOrder.push(fnName)
      })
    })
  }
}

class MockDocument {
  activeElement = {some: 'element'}

  getElementById = function (id) {
    if (id === plannerHeaderId) {
      return {
        getBoundingClientRect() {
          return {top: 0, bottom: 42}
        },
      }
    } else if (id === newActivityId) {
      return {
        getBoundingClientRect() {
          return {top: 0, bottom: 11}
        },
      }
    } else {
      return null
    }
  }
}

class MockStore {
  dispatch = jest.fn()

  getState = jest.fn(() => ({}))
}

function mockAnimationClass(callback) {
  return class MockAnimation {
    constructor(expectedActions, manager) {
      this.expectedActions = expectedActions
      this.manager = manager
      callback(this)
    }

    isReady = jest.fn()

    acceptAction = jest.fn()

    invokeUiWillUpdate = jest.fn()

    invokeUiDidUpdate = jest.fn()

    reset = jest.fn()
  }
}

function defaultMockActionsToAnimations(animations) {
  const push = inst => animations.push(inst)
  return [
    {expected: ['first-mock-action'], animation: mockAnimationClass(push)},
    {expected: ['second-mock-action'], animation: mockAnimationClass(push)},
  ]
}

function createManagerWithMocks(opts = {}) {
  const animations = []
  opts = {
    plannerActive: () => true,
    animator: new MockAnimator(),
    document: new MockDocument(),
    actionsToAnimations: defaultMockActionsToAnimations(animations),
    ...opts,
  }
  const manager = new Manager(opts)
  const store = new MockStore()
  manager.setStore(store)
  manager.setOffsetElementIds(plannerHeaderId, newActivityId)

  return {
    manager,
    animator: opts.animator,
    doc: opts.document,
    store,
    animations,
  }
}

describe('registerAnimatable', () => {
  it('throws if does not recognize the registry name', () => {
    const {manager} = createManagerWithMocks()
    expect(() => manager.registerAnimatable('~does not exist~')).toThrow()
  })
})

describe('action handling', () => {
  it('translates actions into specific handlers', () => {
    const {manager} = createManagerWithMocks()
    manager.handleSomeAction = jest.fn()
    const action = {type: 'SOME_ACTION'}
    manager.handleAction(action)
    expect(manager.handleSomeAction).toHaveBeenCalledWith(action)
  })

  it('does not bork on an action it does not handle', () => {
    const {manager} = createManagerWithMocks()
    const action = {type: 'DOES_NOT_EXIST'}
    expect(() => manager.handleAction(action)).not.toThrow()
  })

  describe('srAlert calls', () => {
    let alertMocks = null
    beforeEach(() => {
      alertMocks = {
        visualSuccessCallback: jest.fn(),
        visualErrorCallback: jest.fn(),
        srAlertCallback: jest.fn(),
      }
      alertInitialize(alertMocks)
      return alertMocks
    })

    it('performs an srAlert when items are initially loading', () => {
      const {manager} = createManagerWithMocks()
      manager.handleAction(startLoadingItems())
      expect(alertMocks.srAlertCallback).toHaveBeenCalledWith('loading')
    })

    it('performs an srAlert when future items are loading', () => {
      const {manager} = createManagerWithMocks()
      manager.handleAction(gettingFutureItems())
      expect(alertMocks.srAlertCallback).toHaveBeenCalledWith('loading')
    })

    it('performs an srAlert when past items are loading', () => {
      const {manager} = createManagerWithMocks()
      manager.handleAction(gettingPastItems())
      expect(alertMocks.srAlertCallback).toHaveBeenCalledWith('loading')
    })

    it('performs an srAlert when days are loaded', () => {
      const srAlertMock = jest.fn()
      alertInitialize({
        srAlertCallback: srAlertMock,
      })
      const {manager} = createManagerWithMocks()
      manager.handleAction(
        gotItemsSuccess([{uniqueId: 'day-1-group-1-item-0'}, {uniqueId: 'day-1-group-0-item-0'}])
      )
      expect(srAlertMock).toHaveBeenCalled()
    })

    it('performs an srAlert when grades are loading', () => {
      const {manager} = createManagerWithMocks()
      manager.handleAction(startLoadingGradesSaga())
      expect(alertMocks.srAlertCallback).toHaveBeenCalledWith('Loading Grades')
    })

    it('performs an srAlert when grades are loaded', () => {
      const {manager} = createManagerWithMocks()
      manager.handleAction(gotGradesSuccess())
      expect(alertMocks.srAlertCallback).toHaveBeenCalledWith('Grades Loaded')
    })
  })

  it('dispatches actions to the animations', () => {
    const {manager, animations} = createManagerWithMocks()
    const theAction = {type: 'some-action'}
    manager.handleAction(theAction)
    animations.forEach(animation => {
      expect(animation.acceptAction).toHaveBeenCalledWith(theAction)
    })
  })

  it('calls invokeUiWillUpdate lifecycle methods on ready animations', () => {
    const {manager, animations} = createManagerWithMocks()
    animations[1].isReady.mockReturnValue(true)
    manager.preTriggerUpdates()
    expect(animations[0].invokeUiWillUpdate).not.toHaveBeenCalled()
    expect(animations[1].invokeUiWillUpdate).toHaveBeenCalled()
  })

  it('calls invokeUiDidUpdate lifecycle methods on ready animations', () => {
    const {manager, animations} = createManagerWithMocks()
    animations[1].isReady.mockReturnValue(true)
    manager.triggerUpdates()
    expect(animations[0].invokeUiDidUpdate).not.toHaveBeenCalled()
    expect(animations[1].invokeUiDidUpdate).toHaveBeenCalled()
  })

  it('calls both invokeUiWillUpdate and invokeUiDidUpdate when the ui state is unchanged', () => {
    const {manager, animations} = createManagerWithMocks()
    animations[0].isReady.mockReturnValue(true)
    const theAction = {some: 'action'}
    manager.uiStateUnchanged(theAction)
    expect(animations[0].invokeUiWillUpdate).toHaveBeenCalled()
    expect(animations[0].invokeUiDidUpdate).toHaveBeenCalled()
    expect(animations[1].invokeUiWillUpdate).not.toHaveBeenCalled()
    expect(animations[1].invokeUiDidUpdate).not.toHaveBeenCalled()
  })

  it('skips sending actions to animations when planner is not active', () => {
    const {manager, animations} = createManagerWithMocks({plannerActive: () => false})
    manager.handleAction({some: 'action'})
    expect(animations[0].acceptAction).not.toHaveBeenCalled()
  })

  it('skips lifecycle methods when planner is not active', () => {
    const {manager, animations} = createManagerWithMocks({plannerActive: () => false})
    animations[0].isReady.mockReturnValue(true)
    manager.preTriggerUpdates()
    manager.triggerUpdates()
    manager.uiStateUnchanged({some: 'action'})
    expect(animations[0].invokeUiWillUpdate).not.toHaveBeenCalled()
    expect(animations[0].invokeUiDidUpdate).not.toHaveBeenCalled()
  })
})

describe('deleting an opportunity', () => {
  it('sets focus to an opportunity', () => {
    const {manager, animator} = createManagerWithMocks()
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-1'}, 0, ['1'])
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-2'}, 1, ['2'])
    manager.handleDismissedOpportunity(dismissedOpportunity({plannable_id: '2'}))
    manager.preTriggerUpdates()
    manager.triggerUpdates()
    expect(animator.focusElement).toHaveBeenCalledWith('opp-1')
  })

  it('uses the opportunity fallback if one is given', () => {
    const {manager, animator} = createManagerWithMocks()
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-1'}, 0, ['1'])
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-2'}, 1, ['2'])
    const fakeFallback = {getFocusable: () => 'fallback', getScrollable: () => 'scroll'}
    manager.registerAnimatable('opportunity', fakeFallback, -1, [
      '~~~opportunity-fallback-focus~~~',
    ])
    manager.handleDismissedOpportunity(dismissedOpportunity({plannable_id: '1'}))
    manager.preTriggerUpdates()
    manager.triggerUpdates()
    expect(animator.focusElement).toHaveBeenCalledWith('fallback')
  })

  it('gives up setting opportunity focus there is no fallback', () => {
    const {manager, animator} = createManagerWithMocks()
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-1'}, 0, ['1'])
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-2'}, 1, ['2'])
    manager.handleDismissedOpportunity(dismissedOpportunity({plannable_id: '1'}))
    manager.preTriggerUpdates()
    manager.triggerUpdates()
    expect(animator.focusElement).not.toHaveBeenCalled()
  })
})

describe('update handling', () => {
  it('clears animation plans between triggers', () => {
    const {manager, animator} = createManagerWithMocks()
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-1'}, 0, ['1'])
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-2'}, 1, ['2'])
    manager.handleDismissedOpportunity(dismissedOpportunity({plannable_id: '1'}))
    manager.preTriggerUpdates()
    manager.triggerUpdates()
    animator.focusElement.mockClear()
    manager.preTriggerUpdates()
    manager.triggerUpdates()
    expect(animator.focusElement).not.toHaveBeenCalled()
  })
})

describe('managing nai scroll position', () => {
  function naiFixture(naiAboveScreen) {
    const {manager, store} = createManagerWithMocks()
    store.getState.mockReturnValue({ui: {naiAboveScreen}})
    const gbcr = jest.fn()
    const nai = {
      getScrollable() {
        return {getBoundingClientRect: gbcr}
      },
    }
    manager.registerAnimatable('day', {}, 0, ['nai-unique-id'])
    manager.registerAnimatable('group', {}, 0, ['nai-unique-id'])
    manager.registerAnimatable('new-activity-indicator', nai, 0, ['nai-unique-id'])
    return {manager, store, gbcr}
  }

  it('set to above when nai goes above the screen', () => {
    const {manager, store, gbcr} = naiFixture(false)
    gbcr.mockReturnValueOnce({top: -1})
    manager.handleScrollPositionChange()
    expect(store.dispatch).toHaveBeenLastCalledWith(setNaiAboveScreen(true))
  })

  it('set to below when nai goes below sticky offset', () => {
    const {manager, store, gbcr} = naiFixture(true)
    gbcr.mockReturnValueOnce({top: 84})
    manager.handleScrollPositionChange()
    expect(store.dispatch).toHaveBeenLastCalledWith(setNaiAboveScreen(false))
  })

  it('does not set nai to below when nai is positive but less than the sticky offset', () => {
    const {manager, store, gbcr} = naiFixture(false)
    gbcr.mockReturnValueOnce({top: 41})
    manager.handleScrollPositionChange()
    expect(store.dispatch).not.toHaveBeenCalled()
  })

  it('does not send redundant nai above actions', () => {
    const {manager, store, gbcr} = naiFixture(false)
    gbcr.mockReturnValueOnce({top: 84})
    manager.handleScrollPositionChange()
    expect(store.dispatch).not.toHaveBeenCalled()
  })

  it('does not send redundant nai below actions', () => {
    const {manager, store, gbcr} = naiFixture(true)
    gbcr.mockReturnValueOnce({top: 8})
    manager.handleScrollPositionChange()
    expect(store.dispatch).not.toHaveBeenCalled()
  })
})

describe('fallback focus', () => {
  it('focuses the specified fallback focus', () => {
    const {manager, animator} = createManagerWithMocks()
    const fakeFallback = {getFocusable: () => 'fallback', getScrollable: () => 'scroll'}
    manager.registerAnimatable('item', fakeFallback, -1, [specialFallbackFocusId('item')])
    manager.focusFallback('item')
    expect(animator.focusElement).toHaveBeenCalledWith('fallback')
  })
})
