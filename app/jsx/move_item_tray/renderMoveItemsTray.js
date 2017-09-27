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

import React from 'react';
import ReactDOM from 'react-dom';
import MoveItemTray from 'jsx/move_item_tray/MoveItemTray';
import NestedMoveItemTray from 'jsx/move_item_tray/NestedMoveItemTray';

export function renderMoveItemsTray(options) {
  const { movePanelRoot, model, moveTraySubmit, closeFunction, trayTitle } = options;
  ReactDOM.render(
    <MoveItemTray
      currentItem={{
        id: model.attributes.id,
        title: model.attributes.title || model.attributes.name
      }}
      onExited={() => {
        ReactDOM.unmountComponentAtNode(movePanelRoot)
        closeFunction()
      }}
      onMoveTraySubmit={moveTraySubmit}
      moveSelectionList={model.collection.models.filter(item => item.attributes.id !== model.attributes.id)}
      title={trayTitle}
      initialOpenState
    />, movePanelRoot);
};

export function renderNestedMoveItemsTray(options) {
  const { movePanelRoot, model, moveTraySubmit, closeFunction,
    trayTitle, parentGroups, parentTitleLabel, childKey } = options;

  ReactDOM.render(
    <NestedMoveItemTray
      currentItem={{
        id: model.attributes.id,
        title: model.attributes.title || model.attributes.name
      }}
      onExited={() => {
        ReactDOM.unmountComponentAtNode(movePanelRoot)
        closeFunction()
      }}
      onMoveTraySubmit={moveTraySubmit}
      title={trayTitle}
      initialOpenState
      parentGroups={parentGroups}
      parentTitleLabel={parentTitleLabel}
      childKey={childKey}
    />, movePanelRoot);
};
