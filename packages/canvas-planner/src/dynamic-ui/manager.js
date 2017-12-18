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

import _ from 'lodash';
import changeCase from 'change-case';
import {AnimatableRegistry} from './animatable-registry';
import {Animator} from './animator';
import {isNewActivityItem} from '../utilities/statusUtils';
import {daysToItems} from '../utilities/daysUtils';
import {srAlert} from '../utilities/alertUtils';
import formatMessage from '../format-message';

export class DynamicUiManager {
  constructor (opts = {animator: new Animator(), document: document}) {
    this.animator = opts.animator;
    this.document = opts.document;
    this.animatableRegistry = new AnimatableRegistry();
    this.animationPlan = {};
    this.stickyOffset = 0;
  }

  setStickyOffset (offset) {
    this.stickyOffset = offset;
  }

  registerAnimatable = (type, component, index, itemIds) => {
    this.animatableRegistry.register(type, component, index, itemIds);
  }

  deregisterAnimatable = (type, component, itemIds) => {
    this.animatableRegistry.deregister(type, component, itemIds);
  }

  clearAnimationPlan () {
    this.animationPlan = {};
  }

  animationWillScroll () {
    return this.animationPlan.scrollToLastNewActivity ||
      this.animationPlan.focusLastNewItem ||
      this.animationPlan.focusItem ||
      // This works around a chrome bug where focusing something in the sticky header jumps the
      // scroll position to the top of the document, so we need to maintain the scroll position.
      this.animationPlan.focusPreOpenTrayElement
    ;
  }

  shouldMaintainCurrentSrcollingPosition () {
    // We need to maintain our scrolling postion in the viewport if:
    // 1. we will not animate and do not want to scroll from the current position at all,
    //    which is the case when the user is scrolling into the past and we load more items, or
    // 2. we are about to animate a scroll, in which case we want to start in the current spot
    return !!(this.animationPlan.noScroll || this.animationWillScroll());
  }

  preTriggerUpdates = (fixedElement) => {
    const animationPlan = this.animationPlan;
    if (!animationPlan.ready) return;

    if (fixedElement && this.shouldMaintainCurrentSrcollingPosition()) {
      this.animator.maintainViewportPosition(fixedElement);
    }
  }

  triggerUpdates = () => {
    const animationPlan = this.animationPlan;
    if (!animationPlan.ready) return;

    if (this.animationPlan.scrollToLastNewActivity) {
      this.triggerNewActivityAnimations();
    } else if (this.animationPlan.focusLastNewItem) {
      this.triggerFocusLastNewItem();
    } else if (this.animationPlan.focusFirstNewItem) {
      this.triggerFocusFirstNewItem();
    } else if (this.animationPlan.focusItem) {
      this.triggerFocusItem();
    } else if (this.animationPlan.focusPreOpenTrayElement && this.animationPlan.preOpenTrayElement) {
      this.triggerFocusPreOpenTrayElement();
    }

    this.clearAnimationPlan();
  }

  triggerFocusFirstNewItem () {
    const {itemIds: newDayItemIds} =
      this.animatableRegistry.getFirstComponent('day', this.animationPlan.newItemIds);
    const {component: firstNewGroup, itemIds: firstGroupItemIds} =
      this.animatableRegistry.getFirstComponent('group', newDayItemIds);

    let focusable = firstNewGroup.getFocusable();
    if (focusable == null) {
      const {component: firstNewGroupItem} = this.animatableRegistry.getFirstComponent('item', firstGroupItemIds);
      focusable = firstNewGroupItem.getFocusable();
    }

    this.animator.focusElement(focusable);
  }

  triggerFocusLastNewItem () {
    const {itemIds: newDayItemIds} =
      this.animatableRegistry.getLastComponent('day', this.animationPlan.newItemIds);
    const {component: lastNewGroup, itemIds: newGroupItemIds} =
      this.animatableRegistry.getLastComponent('group', newDayItemIds);
    const {component: lastNewItem} =
      this.animatableRegistry.getLastComponent('item', newGroupItemIds);
    this.animator.focusElement(lastNewItem.getFocusable());
    this.animator.scrollTo(lastNewGroup.getScrollable(), this.stickyOffset);
  }

  triggerNewActivityAnimations () {
    if (!this.animationPlan.scrollToLastNewActivity) return;
    const newActivityItems = this.animationPlan.newItems.filter(item => isNewActivityItem(item));
    const newActivityItemIds = newActivityItems.map(item => item.uniqueId);
    if (newActivityItemIds.length === 0) return;

    let {itemIds: newActivityDayItemIds} =
      this.animatableRegistry.getLastComponent('day', newActivityItemIds);
    // only want groups in the day that have new activity items
    newActivityDayItemIds = _.intersection(newActivityDayItemIds, newActivityItemIds);

    const {component: newActivityGroup, itemIds: newActivityGroupItemIds} =
      this.animatableRegistry.getLastComponent('group', newActivityDayItemIds);

    const {component: newActivityItem} =
      this.animatableRegistry.getLastComponent('item', newActivityGroupItemIds);

    this.animator.focusElement(newActivityItem.getFocusable());
    this.animator.scrollTo(newActivityGroup.getScrollable(), this.stickyOffset);
  }

  triggerFocusItem () {
    const itemToFocus = this.animatableRegistry.getComponent('item', this.animationPlan.focusItem);
    this.animator.focusElement(itemToFocus.component.getFocusable(this.animationPlan.trigger));
    this.animator.scrollTo(itemToFocus.component.getScrollable(), this.stickyOffset);
  }

  triggerFocusPreOpenTrayElement () {
    this.animator.focusElement(this.animationPlan.preOpenTrayElement);

    // make sure the focused item is in view in case they scrolled away from it while the tray was open
    if (!this.animationPlan.noScroll) {
      this.animator.scrollTo(this.animationPlan.preOpenTrayElement, this.stickyOffset);
    }
  }

  handleAction = (action) => {
    const handlerSuffix = changeCase.pascal(action.type);
    const handlerName = `handle${handlerSuffix}`;
    const handler = this[handlerName];
    if (handler) handler(action);
  }

  handleStartLoadingItems = (action) => {
    this.animationPlan.focusFirstNewItem = true;
  }

  handleGettingFutureItems = (action) => {
    this.animationPlan.focusFirstNewItem = true;
  }

  handleGettingPastItems = (action) => {
    if (action.payload.seekingNewActivity) {
      this.animationPlan.scrollToLastNewActivity = true;
    } else {
      // if there are no past items yet, focus on the last one
      // otherwise leave scrolling position where it is and let
      // the user simply scroll into the newly loaded ones as they choose to
      this.animationPlan.focusLastNewItem = !action.payload.somePastItemsLoaded;
      this.animationPlan.noScroll = !!action.payload.somePastItemsLoaded;
    }
  }

  handleGotDaysSuccess = (action) => {
    const newDays = action.payload.internalDays;
    const newItems = daysToItems(newDays);
    srAlert(
      formatMessage(`Loaded { count, plural,
        =0 {# items}
        one {# item}
        other {# items}
      }`, { count: newItems.length})
    );

    if (!newItems.length) return;
    this.animationPlan.ready = true;

    this.animationPlan.newItems = newItems;
    this.animationPlan.newItemIds = newItems.map(item => item.uniqueId);

    const sortedItems = _.sortBy(newItems, item => item.date);
    this.animationPlan.firstNewItem = sortedItems[0];
    this.animationPlan.lastNewItem = sortedItems[sortedItems.length - 1];
  }

  handleOpenEditingPlannerItem = (action) => {
    this.animationPlan.preOpenTrayElement = this.document.activeElement;
  }

  handleCancelEditingPlannerItem = (action) => {
    Object.assign(this.animationPlan, {focusPreOpenTrayElement: true, ready: true, ...action.payload});
  }

  handleSavedPlannerItem = (action) => {
    this.animationPlan.focusItem = action.payload.item.uniqueId;
    if (!action.payload.isNewItem && this.animationPlan.preOpenTrayElement) {
      this.animationPlan.focusPreOpenTrayElement = true;
      this.animationPlan.trigger = 'update';
    }
    this.animationPlan.ready = true;
  }

  handleDeletedPlannerItem = (action) => {
    const sortedItems = this.animatableRegistry.getAllItemsSorted();
    if (sortedItems.length === 1) return; // give up, no items to receive focus
    const doomedItem = action.payload;
    const doomedIndex = sortedItems.findIndex(item => item.itemIds[0] === doomedItem.uniqueId);
    let newItemIndex = doomedIndex + 1;
    if (newItemIndex === sortedItems.length) newItemIndex = doomedIndex - 1;
    this.animationPlan.focusItem = sortedItems[newItemIndex].itemIds[0];
    this.animationPlan.ready = true;
  }
}
