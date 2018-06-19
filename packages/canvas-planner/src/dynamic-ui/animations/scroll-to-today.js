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
import formatMessage from 'format-message';
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
  const {component, isToday} = findTodayOrNext(manager.getRegistry());
  if (component) {
    if (component.getScrollable()) {
      // scroll Today into view
      manager.getAnimator().scrollTo(todayElem, manager.totalOffset(), () => {
        // then, if necessary, scroll today's or next todo item into view but not all the way to the top
        manager.getAnimator().scrollTo(component.getScrollable(), manager.totalOffset() + todayElem.offsetHeight, () => {
          // finally, focus the item
          component.getFocusable() && component.getFocusable().focus();
        });
      });
    }
    if (!isToday) {
      // tell the screenreader user where we wound up
      alert(formatMessage("There's nothing today.  Heading to the next item due."));
    }
  } else {
    // there's nothing to focus. leave focus on Today button
    manager.getAnimator().scrollTo(todayElem, this.manager().totalOffset());
  }
}

function findTodayOrNext (registry) {
  const today = moment();
  const todayOrNextItem = registry.getAllItemsSorted().find(item => {
    return item.component.props.date >= today;
  });
  const component = todayOrNextItem && todayOrNextItem.component;
  return {component, isToday: component.props.date.isSame(today, 'day')};
}
