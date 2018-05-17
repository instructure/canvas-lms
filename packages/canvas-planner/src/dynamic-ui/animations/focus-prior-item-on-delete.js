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
import { specialFallbackFocusId } from '../util';

export class FocusPriorItemOnDelete extends Animation {
  setItemFocusUniqueId = null

  uiWillUpdate () {
    const action = this.acceptedAction('DELETED_PLANNER_ITEM');
    const doomedItemComponentId = action.payload.uniqueId;
    const sortedItemComponents = this.registry().getAllItemsSorted();
    const doomedItemComponentIndex = sortedItemComponents.findIndex(
      c => c.componentIds[0] === doomedItemComponentId
    );
    const priorComponentIndex = doomedItemComponentIndex - 1;
    this.setItemFocusUniqueId = priorComponentIndex >= 0 ?
      sortedItemComponents[priorComponentIndex].componentIds[0] :
      specialFallbackFocusId('item');
  }

  uiDidUpdate () {
    const setItemFocusUniqueId = this.setItemFocusUniqueId;
    this.setItemFocusUniqueId = null;

    const itemComponentToFocus = this.registry().getComponent('item', setItemFocusUniqueId);
    if (itemComponentToFocus == null) return;
    // Use a non-zero timeout to work around bug INSTUI-1141 where the Tray
    // will steal focus back after a delete confirmation dialog.
    this.window().setTimeout(() => {
      this.animator().focusElement(itemComponentToFocus.component.getFocusable('delete'));
      this.animator().scrollTo(itemComponentToFocus.component.getScrollable(), this.stickyOffset());
    }, 250);
  }
}
