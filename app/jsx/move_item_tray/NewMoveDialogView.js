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

import axios from 'axios';
import renderMoveItemsTray from 'jsx/move_item_tray/renderMoveItemsTray';
import I18n from 'i18n!move_item_tray';

export default class NewMoveDialogView {
  constructor(options) {
     this.model = options.model;
     this.nested = options.nested;
     this.closeTarget = options.closeTarget;
     this.saveURL = options.saveURL;
     this.onSuccessfulMove = options.onSuccessfulMove;
     this.movePanelParent = options.movePanelParent;
  }

  renderOpenMoveDialog() {
    // We only render the move component first time it opens
    let movePanelRoot = document.getElementById('move_panel_tray');
    if (!movePanelRoot) {
      const movePanelParent = this.movePanelParent;
      const movePanelElement = document.createElement('div');
      movePanelElement.setAttribute('id', 'move_panel_tray');
      movePanelParent.appendChild(movePanelElement);
      movePanelRoot = movePanelElement
    }
    renderMoveItemsTray(movePanelRoot, this.model, this.onMoveItemTray, this.moveTrayClose, I18n.t('Move Discussion'));
  }

  onMoveItemTray = (movedItems) => {
    // this.saveURL can apparently be a function
    axios.post(this.saveURL, {
      order: movedItems.join(',')}
    ).then((response) => {
      this.onSuccessfulMove(response.data.order);
    })
  }

  setCloseFocus(closeButton) {
    this.focusOnCloseItem = closeButton;
  }

  moveTrayClose() {
    this.focusOnCloseItem.focus()
  }
}
