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

import {DynamicUiManager as Manager} from '../manager';
import {dismissedOpportunity, cancelEditingPlannerItem, setNaiAboveScreen, scrollToNewActivity} from '../../actions';
import {gettingPastItems, gotItemsSuccess} from '../../actions/loading-actions';
import { initialize as alertInitialize } from '../../utilities/alertUtils';

class MockAnimator {
  animationOrder = []
  isAboveScreen = jest.fn()
  constructor () {
    ['maintainViewportPosition', 'focusElement', 'scrollTo', 'scrollToTop'].forEach(fnName => {
      this[fnName] = jest.fn(() => {
        this.animationOrder.push(fnName);
      });
    });
  }
}

class MockDocument {
  activeElement = {some: 'element'}
}

class MockStore {
  dispatch = jest.fn()
  getState = jest.fn(() => ({}))
}

function createManagerWithMocks (opts = {}) {
  opts = Object.assign({
    animator: new MockAnimator(),
    document: new MockDocument(),
  }, opts);
  const manager = new Manager(opts);
  const store = new MockStore();
  manager.setStore(store);
  manager.setStickyOffset(42);
  return {manager, animator: opts.animator, doc: opts.document, store };
}

function registerStandardDays (manager, opts = {}) {
  [2, 1, 0].forEach(dayIndex => registerStandardDay(manager, dayIndex, opts));
}

function registerStandardDay (manager, dayIndex, opts = {}) {
  const uniqueId = `day-${dayIndex}`;
  const dayElement = { uniqueId };
  const itemElements = registerStandardGroups(manager, dayIndex, opts);
  manager.registerAnimatable('day', dayElement, dayIndex, itemElements.map(i => i.uniqueId));
}

function registerStandardGroups (manager, dayIndex, opts = {}) {
  let allItemElements = [];
  [2, 1, 0].forEach(groupIndex => {
    const itemElements = registerStandardItems(manager, dayIndex, groupIndex, opts);
    allItemElements = allItemElements.concat(itemElements);
    const uniqueId = `day-${dayIndex}-group-${groupIndex}`;
    const groupElement = {
      uniqueId,
      getFocusable: opts.groupFocusable || (() => `focusable-${uniqueId}`),
      getScrollable: () => `scrollable-${uniqueId}`,
    };
    const itemUniqueIds = itemElements.map(elt => elt.uniqueId);
    manager.registerAnimatable('group', groupElement, groupIndex, itemUniqueIds);
    const naiComponent = {
      uniqueId,
      getFocusable: () => { throw new Error('new activity indicators should not be focused'); },
      getScrollable: () => `scrollable-nai-${uniqueId}`,
    };
    manager.registerAnimatable('new-activity-indicator', naiComponent, groupIndex, itemUniqueIds);
  });
  return allItemElements;
}

function registerStandardItems (manager, dayIndex, groupIndex, opts = {}) {
  return [2, 1, 0].map(itemIndex => {
    const uniqueId = `day-${dayIndex}-group-${groupIndex}-item-${itemIndex}`;
    const itemElement = {
      uniqueId,
      newActivity: itemIndex === 1 ? true : false,
      getFocusable: () => `focusable-${uniqueId}`,
      getScrollable: () => `scrollable-${uniqueId}`
   };
    manager.registerAnimatable('item', itemElement, itemIndex, [uniqueId]);
    return itemElement;
  });
}

beforeEach(() => {
  alertInitialize({
    visualSuccessCallback () {},
    visualErrorCallback () {},
    srAlertCallback () {}
  });
});

describe('registerAnimatable', () => {
  it('throws if does not recognize the registry name', () => {
    const {manager} = createManagerWithMocks();
    expect(() => manager.registerAnimatable('~does not exist~')).toThrow();
  });
});

describe('action handling', () => {
  it('translates actions into specific handlers', () => {
    const {manager} = createManagerWithMocks();
    manager.handleSomeAction = jest.fn();
    const action = {type: 'SOME_ACTION'};
    manager.handleAction(action);
    expect(manager.handleSomeAction).toHaveBeenCalledWith(action);
  });

  it('does not bork on an action it does not handle', () => {
    const {manager} = createManagerWithMocks();
    const action = {type: 'DOES_NOT_EXIST'};
    expect(() => manager.handleAction(action)).not.toThrow();
  });

  it('performs an srAlert when days are loaded', () => {
    const srAlertMock = jest.fn();
    alertInitialize({
      srAlertCallback: srAlertMock
    });
    const {manager} = createManagerWithMocks();
    manager.handleAction(gotItemsSuccess(
      [{uniqueId: 'day-1-group-1-item-0'}, {uniqueId: 'day-1-group-0-item-0'}],
    ));
    expect(srAlertMock).toHaveBeenCalled();
  });
});

describe('getting past items', () => {
  it('maintains the scroll position when loading past items', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleAction(gettingPastItems({seekingNewActivity: false}));
    manager.handleAction(gotItemsSuccess(
      [{uniqueId: 'day-1-group-1-item-0'}, {uniqueId: 'day-1-group-0-item-0'}],
    ));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
  });
});

describe('getting new activity', () => {
  it('just scrolls when a new activity indicator is above the screen', () => {
    const {manager, animator, store} = createManagerWithMocks();
    registerStandardDays(manager);
    animator.isAboveScreen.mockReturnValueOnce(false).mockReturnValueOnce(true);
    manager.handleAction(scrollToNewActivity({additionalOffset: 53}));
    expect(animator.isAboveScreen).toHaveBeenCalledWith('scrollable-nai-day-2-group-2', 42 + 53);
    expect(animator.isAboveScreen).toHaveBeenCalledWith('scrollable-nai-day-2-group-1', 42 + 53);
    expect(animator.scrollTo).toHaveBeenCalledWith('scrollable-nai-day-2-group-1', 42 + 53);
    expect(store.dispatch).not.toHaveBeenCalled();
  });

  it('dispatches loadPastUntilNewActivity when items need to be loaded', () => {
    const {manager, store} = createManagerWithMocks();
    manager.handleAction(scrollToNewActivity({additionalOffset: 53}));
    expect(store.dispatch).toHaveBeenCalled();
    const thunk = store.dispatch.mock.calls[0][0];
    expect(thunk(store.dispatch, store.getState)).toEqual('loadPastUntilNewActivity');
  });

  it('does animations when getting new activity requires loading', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleAction(scrollToNewActivity({additionalOffset: 53}));
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.scrollToTop).toHaveBeenCalled();

    manager.handleAction(gettingPastItems({seekingNewActivity: true}));
    manager.handleAction(gotItemsSuccess([
        {uniqueId: 'day-0-group-2-item-2'},
        {uniqueId: 'day-0-group-1-item-1', newActivity: true},
    ]));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element-again', 'app');
    manager.triggerUpdates();
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element-again');
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-0-group-1');
    expect(animator.scrollTo).toHaveBeenCalledWith('scrollable-nai-day-0-group-1', 42 + 53);
  });

  it('handles the case when there is no new activity in the new items', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleAction(scrollToNewActivity({additionalOffset: 53}));
    manager.handleAction(gettingPastItems({seekingNewActivity: true}));
    manager.handleAction(gotItemsSuccess([
      {uniqueId: 'day-0-group-0-item0'},
    ]));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    // can still maintain the viewport position for the new load
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    // other animations don't happen because we don't know what to animate to.
    expect(animator.focusElement).not.toHaveBeenCalled();
    expect(animator.scrollTo).not.toHaveBeenCalled();
  });
});

describe('manipulating items', () => {
  it('restores previous focus on cancel', () => {
    const {manager, animator, doc} = createManagerWithMocks();
    manager.handleOpenEditingPlannerItem();
    manager.handleAction(cancelEditingPlannerItem({noScroll: false}));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith(doc.activeElement);
    // maintain and scrolling works around a chrome bug
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.scrollTo).toHaveBeenCalledWith(doc.activeElement, 42);
  });

  it('does not scroll on cancel if told not to', () => {
    const {manager, animator, doc} = createManagerWithMocks();
    manager.handleOpenEditingPlannerItem();
    manager.handleAction(cancelEditingPlannerItem({noScroll: true}));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith(doc.activeElement);
    // maintain and scrolling works around a chrome bug
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.scrollTo).not.toHaveBeenCalled();
  });

  it('restores focus to previous focus when saving an existing item', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleOpenEditingPlannerItem();
    manager.handleSavedPlannerItem({payload: {isNewItem: false, item: {uniqueId: 'day-0-group-0-item-0'}}});
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-0-group-0-item-0');
    // maintain and scrolling works around a chrome bug
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.scrollTo).toHaveBeenCalledWith('scrollable-day-0-group-0-item-0', 42);
  });

  it('sets focus to the new item when adding a new item', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleOpenEditingPlannerItem();
    manager.handleSavedPlannerItem({payload: {isNewItem: true, item: {uniqueId: 'day-0-group-0-item-0'}}});
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-0-group-0-item-0');
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.scrollTo).toHaveBeenCalledWith('scrollable-day-0-group-0-item-0', 42);
  });

  describe('deleting an item', () => {
    it('sets focus to the previous item if there is one', () => {
      const {manager, animator} = createManagerWithMocks();
      // when deleting, we need to assume the item has already been registered.
      registerStandardDays(manager);
      manager.handleOpenEditingPlannerItem();
      manager.handleDeletedPlannerItem({payload: {uniqueId: 'day-1-group-1-item-2'}});
      manager.preTriggerUpdates('fixed-element', 'app');
      manager.triggerUpdates();
      expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-1-group-1-item-1');
    });

    it('sets focus to the fallback if there is no previous item', () => {
      const {manager, animator} = createManagerWithMocks();
      registerStandardDays(manager);
      const fakeFallback = {getFocusable: () => 'fallback', getScrollable: () => 'scroll'};
      manager.registerAnimatable('item', fakeFallback, -1, ['~~~item-fallback-focus~~~']);
      manager.handleOpenEditingPlannerItem();
      manager.handleDeletedPlannerItem({payload: {uniqueId: 'day-0-group-0-item-0'}});
      manager.preTriggerUpdates('fixed-element', 'app');
      manager.triggerUpdates();
      expect(animator.focusElement).toHaveBeenCalledWith('fallback');
    });

    it('gives up setting item focus if deleting the first item and there is no fallback', () => {
      const {manager, animator} = createManagerWithMocks();
      registerStandardDays(manager);
      manager.handleOpenEditingPlannerItem();
      manager.handleDeletedPlannerItem({payload: {uniqueId: 'day-0-group-0-item-0'}});
      manager.preTriggerUpdates('fixed-element', 'app');
      manager.triggerUpdates();
      expect(animator.focusElement).not.toHaveBeenCalled();
    });
  });
});

describe('deleting an opportunity', () => {
  it('sets focus to an opportunity', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-1'}, 0, ['1']);
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-2'}, 1, ['2']);
    manager.handleDismissedOpportunity(dismissedOpportunity({plannable_id: '2'}));
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith('opp-1');
  });

  it('uses the opportunity fallback if one is given', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-1'}, 0, ['1']);
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-2'}, 1, ['2']);
    const fakeFallback = {getFocusable: () => 'fallback', getScrollable: () => 'scroll'};
    manager.registerAnimatable('opportunity', fakeFallback, -1, ['~~~opportunity-fallback-focus~~~']);
    manager.handleDismissedOpportunity(dismissedOpportunity({plannable_id: '1'}));
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith('fallback');
  });

  it('gives up setting opportunity focus there is no fallback', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-1'}, 0, ['1']);
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-2'}, 1, ['2']);
    manager.handleDismissedOpportunity(dismissedOpportunity({plannable_id: '1'}));
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).not.toHaveBeenCalled();
  });
});

describe('update handling', () => {
  it('ignores triggers when the animation plan is not ready', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleOpenEditingPlannerItem();
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.animationOrder).toEqual([]);
    expect(animator.focusElement).not.toHaveBeenCalled();
  });

  it('clears animation plans between triggers', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleSavedPlannerItem({payload: {item: {uniqueId: 'day-0-group-0-item-0'}}});
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-0-group-0-item-0');

    animator.focusElement = jest.fn();
    manager.handleAction(gotItemsSuccess([
      {uniqueId: 'day-1-group-0-item-0', newActivity: true},
    ]));
    manager.preTriggerUpdates('fixed-element', 'app');
    manager.triggerUpdates();
    expect(animator.focusElement).not.toHaveBeenCalled();
  });
});

describe('managing nai scroll position', () => {
  function naiFixture (naiAboveScreen) {
    const {manager, store} = createManagerWithMocks();
    store.getState.mockReturnValue({ui: {naiAboveScreen}})
    const gbcr = jest.fn();
    const nai = {
      getScrollable () {
        return { getBoundingClientRect: gbcr };
      }
    };
    manager.registerAnimatable('day', {}, 0, ['nai-unique-id']);
    manager.registerAnimatable('group', {}, 0, ['nai-unique-id']);
    manager.registerAnimatable('new-activity-indicator', nai, 0, ['nai-unique-id']);
    return {manager, store, gbcr};
  }

  it('set to above when nai goes above the screen', () => {
    const {manager, store, gbcr} = naiFixture(false);
    gbcr.mockReturnValueOnce({top: -1});
    manager.handleScrollPositionChange();
    expect(store.dispatch).toHaveBeenLastCalledWith(setNaiAboveScreen(true));
  });

  it('set to below when nai goes below sticky offset', () => {
    const {manager, store, gbcr} = naiFixture(true);
    gbcr.mockReturnValueOnce({top: 84});
    manager.handleScrollPositionChange();
    expect(store.dispatch).toHaveBeenLastCalledWith(setNaiAboveScreen(false));
  });

  it('does not set nai to below when nai is positive but less than the sticky offset', () => {
    const {manager, store, gbcr} = naiFixture(false);
    gbcr.mockReturnValueOnce({top: 41});
    manager.handleScrollPositionChange();
    expect(store.dispatch).not.toHaveBeenCalled();
  });

  it('does not send redundant nai above actions', () => {
    const {manager, store, gbcr} = naiFixture(false);
    gbcr.mockReturnValueOnce({top: 84});
    manager.handleScrollPositionChange();
    expect(store.dispatch).not.toHaveBeenCalled();
  });

  it('does not send redundant nai below actions', () => {
    const {manager, store, gbcr} = naiFixture(true);
    gbcr.mockReturnValueOnce({top: 8});
    manager.handleScrollPositionChange();
    expect(store.dispatch).not.toHaveBeenCalled();
  });
});
