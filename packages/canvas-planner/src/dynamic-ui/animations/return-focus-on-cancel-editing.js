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

export class ReturnFocusOnCancelEditing extends Animation {
  savedActiveElement = null

  fixedElement () {
    return this.app().fixedElementForItemScrolling();
  }

  // Using this function to record the current focus when the tray opens,
  // because uiWillUpdate only happens after the tray is canceled and the
  // focus has changed.
  shouldAcceptOpenEditingPlannerItem (action) {
    this.savedActiveElement = this.document().activeElement;
    // there is no focus if focus is on the body
    if (this.savedActiveElement === this.document().body) this.savedActiveElement = null;
    return true;
  }

  uiDidUpdate () {
    // Need to maintain the viewport position to work around a chome bug that
    // will scroll the viewport to the top of the page when focusing an
    // element in the header, like the plus button.
    this.maintainViewportPositionOfFixedElement();
    if (this.savedActiveElement != null) {
      this.animator().focusElement(this.savedActiveElement);

      // if the focused item is in the header, don't try to scroll it below
      // the header.
      const header = this.document().querySelector('#dashboard_header_container');
      const savedActiveElementInHeader = header && header.contains(this.savedActiveElement);
      if (!savedActiveElementInHeader) {
        this.animator().scrollTo(this.savedActiveElement, this.stickyOffset());
      }
    }
  }
}
