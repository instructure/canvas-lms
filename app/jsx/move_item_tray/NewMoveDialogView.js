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
import { showFlashError } from 'jsx/shared/FlashAlert'
import {renderMoveItemsTray, renderNestedMoveItemsTray} from 'jsx/move_item_tray/renderMoveItemsTray';
import I18n from 'i18n!move_item_tray';

export default class NewMoveDialogView {
  constructor(options) {
    this.nested = options.nested;
    this.model = options.model;
    this.closeTarget = options.closeTarget;
    this.saveURL = options.saveURL;
    this.modalTitle = options.modalTitle;
    this.onSuccessfulMove = options.onSuccessfulMove;
    this.movePanelParent = options.movePanelParent;

    if(options.navigationList) {
      this.navigationList = options.navigationList
    }

    if(options.modules) {
      this.modules = options.modules
    }

    if(options.nested) {
      this.movePanelParent = options.movePanelParent;
      this.childKey = options.childKey;
      this.parentTitleLabel = options.parentTitleLabel;
      this.parentCollection = options.parentCollection;
    }
  }

  renderOpenMoveDialog = () => {
    // We only render the move component first time it opens
    let movePanelRoot = document.getElementById('move_panel_tray');
    if (!movePanelRoot) {
      const movePanelParent = this.movePanelParent;
      const movePanelElement = document.createElement('div');
      movePanelElement.setAttribute('id', 'move_panel_tray');
      movePanelParent.appendChild(movePanelElement);
      movePanelRoot = movePanelElement
    }

    if(this.nested) {
      let parentGroups = this.parentCollection.models;
      if (!this.modules) {
        parentGroups = this.parentCollection.models.map((item) => {
          return {groupId: item.id, name: item.attributes.name || item.attributes.title,
            children: item.get(this.childKey).models.filter(child => child.id !== this.model.attributes.id)}
        });
        renderNestedMoveItemsTray({ movePanelRoot, model: this.model, moveTraySubmit: this.onMoveItemNestedTray, closeFunction:
          this.moveTrayClose, trayTitle: this.modalTitle, parentGroups, parentTitleLabel: this.parentTitleLabel,
          childKey: this.childKey } );
      } else {
        renderNestedMoveItemsTray({ movePanelRoot, model: this.model, moveTraySubmit: this.onMoveItemModulesNestedTray, closeFunction:
          this.moveTrayClose, trayTitle: this.modalTitle, parentGroups, parentTitleLabel: this.parentTitleLabel,
          childKey: this.childKey } );
      }
    } else if(this.navigationList) {
      renderMoveItemsTray({ movePanelRoot, model: this.model, moveTraySubmit: this.onMoveNavigationItem,
        closeFunction: this.moveTrayClose, trayTitle: this.modalTitle });
    } else if(this.modules) {
      renderMoveItemsTray({ movePanelRoot, model: this.model, moveTraySubmit: this.onMoveModuleGroupsTray,
        closeFunction: this.moveTrayClose, trayTitle: this.modalTitle });
    } else {
      renderMoveItemsTray({ movePanelRoot, model: this.model, moveTraySubmit: this.onMoveItemTray,
        closeFunction: this.moveTrayClose, trayTitle: this.modalTitle });
    }
  }

  onMoveNavigationItem = ({ movedItems, action, relativeID }) => {
    this.onSuccessfulMove(movedItems, action, relativeID);
  }

  onMoveItemTray = ({ movedItems }) => {
    // this.saveURL can apparently be a function
    axios.post(this.saveURL, {
      order: movedItems.join(',')}
    ).then((response) => {
      this.onSuccessfulMove(response.data.order);
    }).catch(showFlashError(I18n.t('Failed to Move Items')))
  }

  onMoveItemNestedTray = ({ movedItems, groupID } ) => {
    // this.saveURL can apparently be a function
    axios.post(`${this.saveURL}/${groupID}/reorder`, {
      order: movedItems.join(',')}
    ).then((response) => {
      this.onSuccessfulMove(response.data.order, groupID);
    }).catch(showFlashError(I18n.t('Failed to Move Items')))
  }

  onMoveItemModulesNestedTray = ({ movedItems, itemID, groupID }) => {
    axios.post(`${this.saveURL}/modules/${groupID}/reorder`, {
      order: movedItems.join(',')}
    ).then((response) => {
      this.onSuccessfulMove(response.data, { groupID, itemID});
    }).catch(showFlashError(I18n.t('Failed to Move Items')))
  }

  onMoveModuleGroupsTray = ({ movedItems, action, currentID, relativeID }) => {
    // this.saveURL can apparently be a function
    axios.post(this.saveURL, {
      order: movedItems.join(',')}
    ).then((response) => {
      this.onSuccessfulMove(response.data, { action, currentID, relativeID });
    }).catch(showFlashError(I18n.t('Failed to Move Items')))
  }

  setCloseFocus(closeButton) {
    this.closeTarget = closeButton;
  }

  moveTrayClose = () => {
    setTimeout(() => {
      this.closeTarget.focus()
    }, 100)
  }
}
