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
import {dismissedOpportunity} from '../../actions';
import {gotItemsSuccess} from '../../actions/loading-actions';
import { initialize as alertInitialize } from '../../utilities/alertUtils';

class MockAnimator {
  animationOrder = []

  constructor () {
    ['focusElement', 'maintainViewportPosition', 'scrollTo',
    'queueAnimation', 'runAnimationQueue'].forEach(fnName => {
      this[fnName] = jest.fn(() => {
        this.animationOrder.push(fnName);
      });
    });
  }
}

class MockDocument {
  activeElement = {some: 'element'}
}

function createManagerWithMocks (opts = {}) {
  opts = Object.assign({
    animator: new MockAnimator(),
    document: new MockDocument(),
  }, opts);
  const manager = new Manager(opts);
  manager.setStickyOffset(42);
  return {manager, animator: opts.animator, doc: opts.document};
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
    manager.registerAnimatable('group', groupElement, groupIndex, itemElements.map(i => i.uniqueId));
  });
  return allItemElements;
}

function registerStandardItems (manager, dayIndex, groupIndex, opts = {}) {
  return [2, 1, 0].map(itemIndex => {
    const uniqueId = `day-${dayIndex}-group-${groupIndex}-item-${itemIndex}`;
    const itemElement = {
      uniqueId,
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
});

describe('loading future items', () => {
  it('performs an srAlert when days are loaded', () => {
    const srAlertMock = jest.fn();
    alertInitialize({
      srAlertCallback: srAlertMock
    });
    const {manager} = createManagerWithMocks();
    manager.handleGettingFutureItems();
    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-1-group-1-item-0'}, {uniqueId: 'day-1-group-0-item-0'}],
    ));
    expect(srAlertMock).toHaveBeenCalled();
  });

  it('it focuses the first group of the new items according to ui index', () => {
    // order of operations is important here: simulates actual usage
    const {manager, animator} = createManagerWithMocks();
    manager.handleGettingFutureItems();
    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-1-group-1-item-0'}, {uniqueId: 'day-1-group-0-item-0'}],
    ));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.animationOrder).toEqual(['focusElement']);
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-1-group-0');
  });

  it('falls back to first item in a group if the group has no focusable', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleGettingFutureItems();
    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-0-group-0-item-0'}],
    ));
    registerStandardDays(manager, {groupFocusable: () => null});
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-0-group-0-item-0');
  });

  it('does not bork on an empty list of new items', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleGettingFutureItems();
    manager.handleGotDaysSuccess(gotItemsSuccess([]));
    manager.preTriggerUpdates();
    manager.triggerUpdates();
    expect(animator.animationOrder).toEqual([]);
  });
});

describe('loading past items', () => {
  it('animates to the last item of the last group of the last loaded day according to ui index', () => {
    // order of operations is important here: simulates actual usage
    const {manager, animator} = createManagerWithMocks();
    manager.handleGettingPastItems({payload: {seekingNewActivity: false}});
    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-0-group-2-item-2'}, {uniqueId: 'day-0-group-2-item-1'}],
    ));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-0-group-2-item-2');
    expect(animator.scrollTo).toHaveBeenCalledWith('scrollable-day-0-group-2', 42);
  });

  it('does not animate to newly loaded items on subsequent retrievals', () => {
    // order of operations is important here: simulates actual usage
    const {manager, animator} = createManagerWithMocks();
    manager.handleGettingPastItems({payload: {seekingNewActivity: false, somePastItemsLoaded: true}});
    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-0-group-2-item-2'}, {uniqueId: 'day-0-group-2-item-1'}],
    ));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.focusElement).toHaveBeenCalledTimes(0);
    expect(animator.scrollTo).toHaveBeenCalledTimes(0);
  });
});

describe('getting new activity', () => {
  it('does several animations with getting new activity', () => {
    const {manager, animator} = createManagerWithMocks({firstItemProps: {
      status: {has_feedback: true},
    }});
    registerStandardDay(manager, 1);
    registerStandardDay(manager, 2);
    manager.handleGettingPastItems({payload: {seekingNewActivity: true}});
    manager.handleGotDaysSuccess(gotItemsSuccess([
        {uniqueId: 'day-0-group-2-item-2'},
        {uniqueId: 'day-0-group-1-item-1', newActivity: true},
    ]));
    registerStandardDay(manager, 0);
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-0-group-1-item-2');
    expect(animator.scrollTo).toHaveBeenCalledWith('scrollable-day-0-group-1', 42);
  });

  it('handles the case when there is no new activity in the new items', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleGettingPastItems({payload: {seekingNewActivity: true}});
    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-0-group-0-item0'}],
    ));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element');
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
    manager.handleCancelEditingPlannerItem({});
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith(doc.activeElement);
    // maintain and scrolling works around a chrome bug
    expect(animator.maintainViewportPosition).toHaveBeenCalledWith('fixed-element');
    expect(animator.scrollTo).toHaveBeenCalledWith(doc.activeElement, 42);
  });

  it('does not scroll on cancel if told not to', () => {
    const {manager, animator, doc} = createManagerWithMocks();
    manager.handleOpenEditingPlannerItem();
    manager.handleCancelEditingPlannerItem({payload: {noScroll: true}});
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element');
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
    manager.preTriggerUpdates('fixed-element');
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
    manager.preTriggerUpdates('fixed-element');
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
      manager.preTriggerUpdates('fixed-element');
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
      manager.preTriggerUpdates('fixed-element');
      manager.triggerUpdates();
      expect(animator.focusElement).toHaveBeenCalledWith('fallback');
    });

    it('gives up setting item focus if deleting the first item and there is no fallback', () => {
      const {manager, animator} = createManagerWithMocks();
      registerStandardDays(manager);
      manager.handleOpenEditingPlannerItem();
      manager.handleDeletedPlannerItem({payload: {uniqueId: 'day-0-group-0-item-0'}});
      manager.preTriggerUpdates('fixed-element');
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
    manager.preTriggerUpdates('fixed-element');
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
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.focusElement).toHaveBeenCalledWith('fallback');
  });

  it('gives up setting opportunity focus there is no fallback', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-1'}, 0, ['1']);
    manager.registerAnimatable('opportunity', {getFocusable: () => 'opp-2'}, 1, ['2']);
    manager.handleDismissedOpportunity(dismissedOpportunity({plannable_id: '1'}));
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.focusElement).not.toHaveBeenCalled();
  });
});

describe('update handling', () => {
  it('ignores triggers when no new items have been loaded yet', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleGettingFutureItems();
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.animationOrder).toEqual([]);
    expect(animator.focusElement).not.toHaveBeenCalled();

    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-1-group-0-item-0'}, {uniqueId: 'day-1-group-0-item-1'}],
    ));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.animationOrder).toEqual(['focusElement']);
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-1-group-0');
  });

  it('clears animation plans between triggers', () => {
    const {manager, animator} = createManagerWithMocks();
    manager.handleGettingFutureItems();
    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-0-group-0-item-0'}],
    ));
    registerStandardDays(manager);
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.animationOrder).toEqual(['focusElement']);
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-0-group-0');

    animator.animationOrder = [];

    manager.handleGettingFutureItems();
    manager.handleGotDaysSuccess(gotItemsSuccess(
      [{uniqueId: 'day-3-group-0-item-0'}],
    ));
    registerStandardDay(manager, 3);
    manager.preTriggerUpdates('fixed-element');
    manager.triggerUpdates();
    expect(animator.animationOrder).toEqual(['focusElement']);
    expect(animator.focusElement).toHaveBeenCalledWith('focusable-day-3-group-0');
    expect(animator.maintainViewportPosition).not.toHaveBeenCalled();
    expect(animator.scrollTo).not.toHaveBeenCalled();
  });
});
