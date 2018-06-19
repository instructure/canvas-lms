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

import _ from 'lodash';
import Animation from '../animation';
import {daysToItems} from '../../utilities/daysUtils';
import {isNewActivityItem} from '../../utilities/statusUtils';

export class ScrollToLastLoadedNewActivity extends Animation {
  fixedElement () {
    return this.app().fixedElementForItemScrolling();
  }

  uiDidUpdate () {
    const gotDaysAction = this.acceptedAction('GOT_DAYS_SUCCESS');
    const newDays = gotDaysAction.payload.internalDays;
    const newItems = daysToItems(newDays);
    const newActivityItems = newItems.filter(item => isNewActivityItem(item));
    const newActivityItemIds = newActivityItems.map(item => item.uniqueId);
    if (newActivityItemIds.length === 0) return;

    let {componentIds: newActivityDayComponentIds} =
      this.registry().getLastComponent('day', newActivityItemIds);
    // only want groups in the day that have new activity items
    newActivityDayComponentIds = _.intersection(newActivityDayComponentIds, newActivityItemIds);

    const {component: newActivityIndicator, componentIds: newActivityIndicatorComponentIds} =
      this.registry().getLastComponent('new-activity-indicator', newActivityDayComponentIds);

    // focus the group because it's right beside the new activity indicator. If we put the focus on
    // an item, the focus might be off the screen when we scroll to the new activity indicator.
    const {component: groupComponentToFocus} =
      this.registry().getLastComponent('group', newActivityIndicatorComponentIds);

    this.maintainViewportPositionOfFixedElement();
    this.animator().focusElement(groupComponentToFocus.getFocusable());
    this.animator().scrollTo(newActivityIndicator.getScrollable(), this.manager().totalOffset());
  }
}
