/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import DragFeedback from '../../components/DragFeedback'
import moveStuff from '../util/moveStuff'
import $ from 'jquery'
import {isArray} from 'lodash'

export default {
  itemsToDrag() {
    return this.state.selectedItems
  },
  renderDragFeedback({pageX, pageY}) {
    if (!this.dragHolder) {
      this.dragHolder = $('<div>').appendTo(document.body)
    }
    // This should be in JSX, but /o\
    ReactDOM.render(
      <DragFeedback pageX={pageX} pageY={pageY} itemsToDrag={this.itemsToDrag()} />,
      this.dragHolder[0]
    )
  },

  removeDragFeedback() {
    $(document).off('.MultiDraggableMixin')
    if (this.dragHolder) {
      ReactDOM.unmountComponentAtNode(this.dragHolder[0])
    }
    this.dragHolder = null
  },

  onItemDragStart(event) {
    // IE 10 can't do this stuff:
    try {
      // make it so you can drag stuff to other apps and it will at least copy a list of urls
      // see: https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Recommended_Drag_Types#link
      const itemsToDrag = this.itemsToDrag()
      if (itemsToDrag.length && isArray(itemsToDrag)) {
        event.dataTransfer.setData(
          'text/uri-list',
          itemsToDrag.map(item => item.get('url')).join('\n')
        )
      }

      // replace the default ghost dragging element with a transparent gif
      // since we are going to use our own custom drag image
      const img = new Image()
      img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
      event.dataTransfer.setDragImage(img, 150, 150)
    } catch (error) {
      // no-op
    }

    this.renderDragFeedback(event)
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('Text', 'in_a_dndMixin_drag')

    return $(document).on({
      'dragover.MultiDraggableMixin': event => this.renderDragFeedback(event.originalEvent),
      'dragend.MultiDraggableMixin': this.removeDragFeedback,
    })
  },

  onItemDragEnterOrOver(event, callback) {
    const types = event.dataTransfer.types || []
    if (!types.includes('Text') && !types.includes('text/plain')) return
    event.preventDefault()
    if (callback) return callback(event)
  },

  onItemDragLeaveOrEnd(event, callback) {
    const types = event.dataTransfer.types || []
    if (!types.includes('Text') && !types.includes('text/plain')) return
    if (callback) return callback(event)
  },

  onItemDrop(event, destinationFolder, callback) {
    if (
      (event.dataTransfer.getData('Text') || event.dataTransfer.getData('text/plain')) !==
      'in_a_dndMixin_drag'
    ) {
      return
    }
    event.preventDefault()
    return moveStuff(this.itemsToDrag(), destinationFolder)
      .then(
        () => {
          if (callback) {
            return callback({success: true, event})
          }
        },
        () => {
          if (callback) {
            return callback({success: false, event})
          }
        }
      )
      .done(this.clearSelectedItems)
  },
}
//      @clearSelectedItems()
//      callback(event) if callback
