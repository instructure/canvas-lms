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

export function specialFallbackFocusId (type) {
  return `~~~${type}-fallback-focus~~~`;
}

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

  // If you want to register a fallback focus component when all the things in a list are deleted,
  // register that component with a -1 index and a special unique componentId that looks like
  // this: `~~~${registryName}-fallback-focus~~~` where registryName is one of the
  // AnimatableRegistry collections.
  registerAnimatable = (type, component, index, componentIds) => {
    this.animatableRegistry.register(type, component, index, componentIds);
  }

  deregisterAnimatable = (type, component, componentIds) => {
    this.animatableRegistry.deregister(type, component, componentIds);
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
      this.triggerFocusItemComponent();
    } else if (this.animationPlan.focusOpportunity) {
      this.triggerFocusOpportunity();
    } else if (this.animationPlan.focusPreOpenTrayElement && this.animationPlan.preOpenTrayElement) {
      this.triggerFocusPreOpenTrayElement();
    }

    this.clearAnimationPlan();
  }

  triggerFocusFirstNewItem () {
    const {componentIds: newDayComponentIds} =
      this.animatableRegistry.getFirstComponent('day', this.animationPlan.newComponentIds);
    const {component: firstNewGroupComponent, componentIds: firstGroupComponentIds} =
      this.animatableRegistry.getFirstComponent('group', newDayComponentIds);

    let focusable = firstNewGroupComponent.getFocusable();
    if (focusable == null) {
      const {component: firstNewGroupItem} = this.animatableRegistry.getFirstComponent('item', firstGroupComponentIds);
      focusable = firstNewGroupItem.getFocusable();
    }

    this.animator.focusElement(focusable);
  }

  triggerFocusLastNewItem () {
    const {componentIds: newDayComponentIds} =
      this.animatableRegistry.getLastComponent('day', this.animationPlan.newComponentIds);
    const {component: lastNewGroup, componentIds: newGroupComponentIds} =
      this.animatableRegistry.getLastComponent('group', newDayComponentIds);
    const {component: lastNewItem} =
      this.animatableRegistry.getLastComponent('item', newGroupComponentIds);
    this.animator.focusElement(lastNewItem.getFocusable());
    this.animator.scrollTo(lastNewGroup.getScrollable(), this.stickyOffset);
  }

  triggerNewActivityAnimations () {
    if (!this.animationPlan.scrollToLastNewActivity) return;
    const newActivityItems = this.animationPlan.newItems.filter(item => isNewActivityItem(item));
    const newActivityItemIds = newActivityItems.map(item => item.uniqueId);
    if (newActivityItemIds.length === 0) return;

    let {componentIds: newActivityDayComponentIds} =
      this.animatableRegistry.getLastComponent('day', newActivityItemIds);
    // only want groups in the day that have new activity items
    newActivityDayComponentIds = _.intersection(newActivityDayComponentIds, newActivityItemIds);

    const {component: newActivityGroup, componentIds: newActivityGroupComponentIds} =
      this.animatableRegistry.getLastComponent('group', newActivityDayComponentIds);

    const {component: newActivityComponent} =
      this.animatableRegistry.getLastComponent('item', newActivityGroupComponentIds);

    this.animator.focusElement(newActivityComponent.getFocusable());
    this.animator.scrollTo(newActivityGroup.getScrollable(), this.stickyOffset);
  }

  triggerFocusItemComponent () {
    const itemComponentToFocus = this.animatableRegistry.getComponent('item', this.animationPlan.focusItem);
    if (itemComponentToFocus == null) return;
    this.animator.focusElement(itemComponentToFocus.component.getFocusable(this.animationPlan.trigger));
    this.animator.scrollTo(itemComponentToFocus.component.getScrollable(), this.stickyOffset);
  }

  triggerFocusOpportunity () {
    const oppToFocus = this.animatableRegistry.getComponent('opportunity', this.animationPlan.focusOpportunity);
    if (oppToFocus == null) return;
    this.animator.focusElement(oppToFocus.component.getFocusable(this.animationPlan.trigger));
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

    if (!newItems.length) {
      this.clearAnimationPlan();
      return;
    }
    this.animationPlan.ready = true;

    this.animationPlan.newItems = newItems;
    this.animationPlan.newComponentIds = newItems.map(item => item.uniqueId);

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
    const doomedItemId = action.payload.uniqueId;
    this.planDeletedComponent('item', doomedItemId);
  }

  handleDismissedOpportunity = (action) => {
    const doomedComponentId = action.payload.plannable_id;
    this.planDeletedComponent('opportunity', doomedComponentId);
  }

  // Note that this is actually called before reducers and therefore before the doomed item has
  // actually been removed from the state.
  planDeletedComponent (doomedComponentType, doomedComponentId) {
    const sortedComponents = this.sortedComponentsFor(doomedComponentType);
    const doomedComponentIndex = sortedComponents.findIndex(c => c.componentIds[0] === doomedComponentId);
    const newComponentIndex = this.findFocusIndexAfterDelete(sortedComponents, doomedComponentIndex);
    const animationPlanFocusField = changeCase.camelCase(`focus-${doomedComponentType}`);
    if (newComponentIndex != null) {
      this.animationPlan[animationPlanFocusField] = sortedComponents[newComponentIndex].componentIds[0];
    } else {
      this.animationPlan[animationPlanFocusField] = specialFallbackFocusId(doomedComponentType);
    }
    this.animationPlan.trigger = 'delete';
    this.animationPlan.ready = true;
  }

  sortedComponentsFor (componentType) {
    switch (componentType) {
      case 'item': return this.animatableRegistry.getAllItemsSorted();
      case 'opportunity': return this.animatableRegistry.getAllOpportunitiesSorted();
      default: throw new Error(`unrecognized deleted component type: ${componentType}`);
    }
  }

  // Note that this finds the new focusable index at its current position, not at its new position
  // after the doomed item is removed. This allows retrieval of the new focusable before the doomed
  // item is removed.
  findFocusIndexAfterDelete (sortedFocusables, doomedFocusableIndex) {
    const newFocusableIndex = doomedFocusableIndex - 1;
    if (newFocusableIndex < 0) return null;
    return newFocusableIndex;
  }
}
