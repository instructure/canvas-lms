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

import changeCase from 'change-case';

export default class Animation {
  constructor (expectedActions, manager) {
    if (expectedActions.length === 0) {
      throw new Error('There must be at least one expected action');
    }
    this.expectedActions = expectedActions;
    this._manager = manager;
  }

  //----------------------
  // Overriddable methods
  //----------------------

  // You can create custom methods to determine if an action will be accepted.
  // This lets you write custom logic to determine whether an action meets this
  // animation's criteria. Prefix the method with `shouldAccept`. For example:
  // shouldAcceptGotDaysSuccess(action) {
  //   // custom logic
  //   // return result of custom logic
  // }
  // This will only be invoked if the action is in the list of expected actions.

  // Called to determine if this animation is ready to execute. By default an
  // animation is ready if all of its expected actions have been accepted. You
  // can overwrite this to perform your own readiness logic.
  isReady () {
    return this.acceptedActionsLength() === this.expectedActions.length;
  }

  // Override this to do something before the DOM updates. Only called if
  // `isReady` returned true.
  uiWillUpdate () {}

  // Override this to do something after the DOM updates. Only called if
  // `isReady` returned true. After this returns, the accepted actions will
  // be cleared.
  uiDidUpdate () {}

  // Override this to enable calling `this.maintainViewportPositionOfFixedElement`
  fixedElement () { return null; }

  //------------------------------------
  // Interface methods: Do not override
  //------------------------------------

  // Convenience method for using the animator's maintainViewportPositionFromMemo
  // method. Implement fixedElement to use this.
  maintainViewportPositionOfFixedElement () {
    const fixedElement = this.fixedElement();
    if (fixedElement && this.fixedElementPositionMemo) {
      this.animator().maintainViewportPositionFromMemo(fixedElement, this.fixedElementPositionMemo);
      this.fixedElementPositionMemo = null;
    }
  }

  // Used by the manager to feed actions to the animations
  acceptAction (action) {
    const expectedActionIndex = this.expectedActions.indexOf(action.type);
    // we don't expect this action at all
    if (expectedActionIndex === -1) return false;
    // we expect this action, but not until prior actions have been accepted.
    if (expectedActionIndex > this.acceptedActionsLength()) return false;

    const acceptsName = `shouldAccept${changeCase.pascal(action.type)}`;
    const accepted = this[acceptsName] ? this[acceptsName](action) : true;
    if (accepted) {
      this.removeAcceptedActionsAfter(expectedActionIndex);
      this.acceptedActions[action.type] = action;
    }
    return accepted;
  }

  // The manager should call these lifecycle methods instead of calling the virtual methods directly.
  invokeUiWillUpdate () {
    if (this.executing) return;
    this.executing = true;

    const fixedElement = this.fixedElement();
    if (fixedElement) this.fixedElementPositionMemo = this.animator().elementPositionMemo(fixedElement);

    this.uiWillUpdate();
    this.executing = false;
  }

  // The manager should call these lifecycle methods instead of calling the virtual methods directly.
  invokeUiDidUpdate () {
    if (this.executing) return;
    this.executing = true;
    this.uiDidUpdate();
    this.reset();
    this.executing = false;
  }

  // Get the accepted action of the specified type.
  acceptedAction (actionType) {
    if (!this.isExpectedAction(actionType)) {
      throw new Error(`ERROR: ${this.constructor.name} tried to access unexpected action '${actionType}'`);
    }

    const action = this.acceptedActions[actionType];
    if (!action) {
      throw new Error(`ERROR: ${this.constructor.name} tried to retrieve action '${actionType}' before it was accepted`);
    }

    return action;
  }

  // remove all accepted actions
  reset () {
    this.acceptedActions = {};
    this.fixedElementPositionMemo = null;
  }

  // access to all the different objects an animation could need.
  manager () { return this._manager; }
  registry () { return this.manager().getRegistry(); }
  animator () { return this.manager().getAnimator(); }
  store () { return this.manager().getStore(); }
  app () { return this.manager().getApp(); }
  document () { return this.manager().getDocument(); }
  window () { return this.animator().getWindow(); }
  stickyOffset () { return this.manager().getStickyOffset(); }
  totalOffset () { return this.manager().totalOffset(); }
  //------------------------------------------------------------------
  // Implementation methods: do not use or override the methods below
  //------------------------------------------------------------------

  // Maps action types to the entire accepted action.
  acceptedActions = {}

  // Array of action types this animation can accept.
  expectedActions = []

  // If an animation dispatches an action, this prevents it from invoking itself again.
  executing = false;

  isExpectedAction (actionType) {
    return this.expectedActions.includes(actionType);
  }

  removeAcceptedActionsAfter (actionIndex) {
    for (let i = actionIndex; i < this.expectedActions.length; ++i) {
      delete this.acceptedActions[this.expectedActions[i]];
    }
  }

  acceptedActionsLength () {
    return Object.keys(this.acceptedActions).length;
  }
}
