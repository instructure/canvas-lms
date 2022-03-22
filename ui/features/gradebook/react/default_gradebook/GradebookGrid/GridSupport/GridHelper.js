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

export default class GridHelper {
  constructor(grid) {
    this.grid = grid
  }

  getColumnHeaderNode(columnId) {
    return document.getElementById(this.grid.getUID() + columnId)
  }

  syncScrollPositions() {
    // The scrollable area of SlickGrid is synced when the body scrolls. The
    // header will be updated to match. However, this step is needed to match
    // the body scroll position to the header when the browser automatically
    // scrolls the header to reveal focused elements.
    const $gridContainer = this.grid.getContainerNode()
    const $headerContainer = $gridContainer.querySelector('.headerScroller_1')
    const $bodyContainer = $gridContainer.querySelector('.viewport_1')
    $bodyContainer.scrollLeft = $headerContainer.scrollLeft
  }

  getBeforeGridNode() {
    return this.grid.getContainerNode().firstChild
  }

  getAfterGridNode() {
    return this.grid.getContainerNode().lastChild
  }

  beginEdit() {
    if (this.grid.getOptions().editable) {
      this.grid.editActiveCell()
    }
  }

  commitCurrentEdit() {
    return this.grid.getEditorLock().commitCurrentEdit()
  }

  focus() {
    this.grid.focus()
  }
}
