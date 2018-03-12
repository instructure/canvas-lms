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
import {setNaiAboveScreen} from '../actions';
import {loadPastUntilNewActivity} from '../actions/loading-actions';

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
    this.additionalOffset = 0;
  }

  setStickyOffset (offset) {
    this.stickyOffset = offset;
  }

  setStore (store) {
    this.store = store;
  }

  totalOffset () {
    return this.stickyOffset + this.additionalOffset;
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
    this.animationPlan = this.animationPlan.nextAnimationPlan || {};
  }

  animationWillScroll () {
    return this.animationPlan.scrollToTop ||
      this.animationPlan.scrollToLastNewActivity ||
      this.animationPlan.focusItem ||
      // This works around a chrome bug where focusing something in the sticky header jumps the
      // scroll position to the top of the document, so we need to maintain the scroll position.
      this.animationPlan.focusPreOpenTrayElement
    ;
  }

  shouldMaintainCurrentScrollingPosition () {
    // We need to maintain our scrolling postion in the viewport if:
    // 1. we will not animate and do not want to scroll from the current position at all,
    //    which is the case when the user is scrolling into the past and we load more items, or
    // 2. we are about to animate a scroll, in which case we want to start in the current spot
    return !!(this.animationPlan.noScroll || this.animationWillScroll());
  }

  preTriggerUpdates = (fixedElement, triggerer) => {
    // only the app should be allowed to muck with the scroll position (the header should not).
    if (triggerer === 'app') {
      this.animator.recordFixedElement(fixedElement);
    }
  }

  triggerUpdates = (additionalOffset) => {
    if (additionalOffset != null) this.additionalOffset = additionalOffset;

    const animationPlan = this.animationPlan;
    if (!animationPlan.ready) return;

    if (this.shouldMaintainCurrentScrollingPosition()) {
      this.animator.maintainViewportPosition();
    }

    if (this.animationPlan.scrollToTop) {
      this.triggerScrollToTop();
    } else if (this.animationPlan.scrollToLastNewActivity) {
      this.triggerNewActivityAnimations();
    } else if (this.animationPlan.focusItem) {
      this.triggerFocusItemComponent();
    } else if (this.animationPlan.focusOpportunity) {
      this.triggerFocusOpportunity();
    } else if (this.animationPlan.focusPreOpenTrayElement && this.animationPlan.preOpenTrayElement) {
      this.triggerFocusPreOpenTrayElement();
    }

    this.clearAnimationPlan();
  }

  triggerScrollToTop () {
    this.animator.scrollToTop();
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

    const {component: newActivityIndicator, componentIds: newActivityGroupComponentIds} =
      this.animatableRegistry.getLastComponent('new-activity-indicator', newActivityDayComponentIds);

    // focus the group because it's right beside the new activity indicator. If we put the focus on
    // an item, the focus might be off the screen when we scroll to the new activity indicator.
    const {component: newActivityComponent} =
      this.animatableRegistry.getLastComponent('group', newActivityGroupComponentIds);

    this.animator.focusElement(newActivityComponent.getFocusable());
    this.animator.scrollTo(newActivityIndicator.getScrollable(), this.totalOffset());
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

  handleScrollPositionChange () {
    // if the button is not being shown, don't show it until an nai is
    // actually above the window, not just under the header. This prevents
    // bouncing of the button visibility that happens as we scroll to new
    // activity because showing and hiding the button changes the document
    // height, which changes the scroll position.
    let naiThreshold = this.stickyOffset;
    if (!this.store.getState().ui.naiAboveScreen) {
      naiThreshold = 0;
    }

    const newActivityIndicators = this.animatableRegistry.getAllNewActivityIndicatorsSorted();
    let naiAboveScreen = false;
    if (newActivityIndicators.length > 0) {
      const naiScrollable = newActivityIndicators[0].component.getScrollable();
      naiAboveScreen = naiScrollable.getBoundingClientRect().top < naiThreshold;
    }

    // just to make sure we avoid dispatching on every scroll position change
    if (this.store.getState().ui.naiAboveScreen !== naiAboveScreen) {
      this.store.dispatch(setNaiAboveScreen(naiAboveScreen));
    }
  }

  handleAction = (action) => {
    const handlerSuffix = changeCase.pascal(action.type);
    const handlerName = `handle${handlerSuffix}`;
    const handler = this[handlerName];
    if (handler) handler(action);
  }

  handleGettingPastItems = (action) => {
    if (action.payload.seekingNewActivity) {
      this.animationPlan.scrollToLastNewActivity = true;
    } else {
      // otherwise just don't let the window scroll when past items are loaded.
      this.animationPlan.noScroll = true;
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
  }

  handleOpenEditingPlannerItem = (action) => {
    this.animationPlan.preOpenTrayElement = this.document.activeElement;
  }

  handleCancelEditingPlannerItem = (action) => {
    Object.assign(this.animationPlan, {
      focusPreOpenTrayElement: true,
      ready: true,
      noScroll: action.payload.noScroll,
    });
  }

  handleScrollToNewActivity = (action) => {
    const newActivityIndicators = this.animatableRegistry.getAllNewActivityIndicatorsSorted();
    const lastOffscreenIndicator = newActivityIndicators.reverse().find(indicator => {
      return this.animator.isAboveScreen(indicator.component.getScrollable(), this.totalOffset());
    });
    if (lastOffscreenIndicator) {
      // there's no state update, so we can just do it now and not muck with the animationPlan
      this.animator.scrollTo(lastOffscreenIndicator.component.getScrollable(), this.totalOffset());
    } else {
      // if there's more we could load, then we should do that.
      // we're assuming there is more to load if this action happens.
      this.store.dispatch(loadPastUntilNewActivity());
      // scroll to the top first so they can see the loading indicator.
      this.animationPlan = {nextAnimationPlan: this.animationPlan};
      this.animationPlan.scrollToTop = true;
      this.animationPlan.ready = true;
    }
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
