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

import moment from 'moment-timezone';
import formatMessage from '../../format-message';
import Animation from '../animation';
import {loadPastUntilToday} from '../../actions/loading-actions';
import { alert } from '../../utilities/alertUtils';

export class ScrollToToday extends Animation {
  uiDidUpdate () {
    const t = this.document().querySelector('.planner-today h2');
    if (t) {
      scrollAndFocusTodayItem(this.manager(), t);
    } else {
      this.animator().scrollToTop();
      this.store().dispatch(loadPastUntilToday());
    }
  }
}

export function scrollAndFocusTodayItem (manager, todayElem) {
  const {component, when} = findTodayOrNearest(manager.getRegistry(), manager.getStore().getState().timeZone);
  if (component) {
    if (component.getScrollable()) {
      // scroll Today into view
      manager.getAnimator().forceScrollTo(todayElem, manager.totalOffset(), () => {
        // then, if necessary, scroll today's or next todo item into view but not all the way to the top
        manager.getAnimator().scrollTo(component.getScrollable(), manager.totalOffset() + todayElem.offsetHeight, () => {
          if (when === 'after') {
            // tell the user where we wound up
            alert(formatMessage("Nothing planned today. Selecting next item."));
          } else if (when === 'before') {
            alert(formatMessage("Nothing planned today. Selecting most recent item."));
          }
          // finally, focus the item
          if (component.getFocusable()) {
            manager.getAnimator().focusElement(component.getFocusable());
          }
        });
      });
    }
  } else {
    // there's nothing to focus. leave focus on Today button
    manager.getAnimator().forceScrollTo(todayElem, manager.totalOffset());
  }
}

// Find an item that's due that's
// 1. the first item due today, and if there isn't one
// 2. the next item due after today, and if there isn't one
// 3. the most recent item still due from the past
function findTodayOrNearest (registry, tz) {
  const today = moment().tz(tz).startOf('day');
  const allItems = registry.getAllItemsSorted();
  let lastInPast = null;
  let firstInFuture = null;

  // find the before and after today items due closest to today
  for (let i = 0; i < allItems.length; ++i) {
    const item = allItems[i];
    if (item.component && item.component.props.date) {
      const date = item.component.props.date;
      if (date.isBefore(today, 'day')) {
        lastInPast = item.component;
      } else if (date.isSame(today, 'day') || date.isAfter(today, 'day')) {
        firstInFuture = item.component;
        break;
      }
    }
  }
  // if there's an item in the future, prefer it
  const component = firstInFuture || lastInPast;

  let when = 'never';
  if (component) {
    if (component === firstInFuture) {
      if (component.props.date.isSame(today, 'day')) {
        when = 'today';
      } else {
        when = 'after';
      }
    } else if (component === lastInPast) {
      when = 'before';
    }
  }
  return {component, when};
}
