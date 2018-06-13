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

import Animation from '../animation';
import formatMessage from '../../format-message';
import {alert} from '../../utilities/alertUtils';

export class FocusItemOnSave extends Animation {
  fixedElement () {
    return this.app().fixedElementForItemScrolling();
  }

  uiDidUpdate () {
    const action = this.acceptedAction('SAVED_PLANNER_ITEM');
    const savedItemUniqueId = action.payload.item.uniqueId;
    const itemComponentToFocus = this.registry().getComponent('item', savedItemUniqueId);
    if (itemComponentToFocus != null) {
      if (!action.payload.wasToggled) {
        this.animator().focusElement(itemComponentToFocus.component.getFocusable('update'));
      }
        this.maintainViewportPositionOfFixedElement();
      this.animator().scrollTo(itemComponentToFocus.component.getScrollable(), this.stickyOffset());
    } else {
      alert(formatMessage('Success: To Do created'));
    }
  }
}
