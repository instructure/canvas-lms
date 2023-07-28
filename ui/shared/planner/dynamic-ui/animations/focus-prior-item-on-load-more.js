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

import Animation from '../animation'

export class FocusPriorItemOnLoadMore extends Animation {
  shouldAcceptGettingFutureItems(action) {
    return action.payload.loadMoreButtonClicked
  }

  uiDidUpdate() {
    const newDays = this.acceptedAction('GOT_DAYS_SUCCESS').payload.internalDays
    const firstNewItem = newDays[0][1][0]
    const allRegisteredItemComponents = this.registry().getAllItemsSorted()
    const indexOfFirstNewItemComponent = allRegisteredItemComponents.findIndex(
      itemComponent => itemComponent.componentIds[0] === firstNewItem.uniqueId
    )
    const indexOfPriorItemComponent = indexOfFirstNewItemComponent - 1
    if (indexOfPriorItemComponent < 0) {
      // eslint-disable-next-line no-console
      console.error('FocusPriorItemOnLoadMore could not find the item that should receive focus')
      return
    }
    const priorItemComponent = allRegisteredItemComponents[indexOfPriorItemComponent]
    this.animator().focusElement(priorItemComponent.component.getFocusable())
  }
}
