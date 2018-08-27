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

import { ReactWrapper } from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme';

const MENU_CONTENT_REF_MAP = {
  'Sort by': 'sortByMenuContent',
  'Display as': 'displayAsMenuContent',
  'Secondary info': 'secondaryInfoMenuContent',
};

// the only requirement is that the individual spec files define their own
// `mountAndOpenOptions` function on `this`.
function findMenuContent (props) {
  this.wrapper = this.mountAndOpenOptions(props);
  return new ReactWrapper([this.wrapper.node.optionsMenuContent], this.wrapper.node);
}

function findFlyout (props, flyoutLabel) {
  const menuContent = findMenuContent.call(this, props)
  const flyouts = menuContent.find('Menu').map(flyout => flyout);
  return flyouts.find(menuItem => menuItem.text().trim() === flyoutLabel);
}

function findFlyoutMenuContent (props, flyoutLabel) {
  const flyout = findFlyout.call(this, props, flyoutLabel)
  // find menu item
  flyout.find('button').simulate('mouseOver');
  const flyoutContentRefFn = MENU_CONTENT_REF_MAP[flyoutLabel];
  return new ReactWrapper([this.wrapper.node[flyoutContentRefFn]], this.wrapper.node);
}

function findMenuItem (props, firstMenuItemLabel, secondMenuItemLabel) {
  const menuContent = findFlyoutMenuContent.call(this, props, firstMenuItemLabel);
  const subMenuItems = menuContent.find('MenuItem').map(menuItem => menuItem);
  return subMenuItems.find(menuItem => menuItem.text().trim() === secondMenuItemLabel);
}

export { findMenuItem, findFlyoutMenuContent, findFlyout, findMenuContent };
