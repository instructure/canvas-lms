#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!react_files'
  'react'
  'react-dom'
  'jsx/files/DragFeedback'
  '../utils/moveStuff'
  'compiled/models/Folder'
  'jquery'
  'underscore'
], (I18n, React, ReactDOM, DragFeedback, moveStuff, Folder, $, _) ->

  dndMixin =

    itemsToDrag: -> @state.selectedItems

    renderDragFeedback: ({pageX, pageY}) ->
      @dragHolder ||= $('<div>').appendTo(document.body)
      # This should be in JSX, but /o\
      ReactDOM.render(React.createElement(DragFeedback, {
        pageX: pageX
        pageY: pageY
        itemsToDrag: @itemsToDrag()
      }), @dragHolder[0])

    removeDragFeedback: ->
      $(document).off('.MultiDraggableMixin')
      ReactDOM.unmountComponentAtNode(@dragHolder[0]) if @dragHolder
      @dragHolder = null

    onItemDragStart: (event) ->
      # IE 10 can't do this stuff:
      try
        # make it so you can drag stuff to other apps and it will at least copy a list of urls
        # see: https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Recommended_Drag_Types#link
        itemsToDrag = @itemsToDrag()
        event.dataTransfer.setData('text/uri-list', itemsToDrag.map((item) -> item.get('url')).join("\n")) if itemsToDrag.length and _.isArray(itemsToDrag)

        # replace the default ghost dragging element with a transparent gif
        # since we are going to use our own custom drag image
        img = new Image
        img.src = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
        event.dataTransfer.setDragImage(img, 150, 150)

      @renderDragFeedback(event)
      event.dataTransfer.effectAllowed = 'move'
      event.dataTransfer.setData('Text', 'in_a_dndMixin_drag')

      $(document).on
        'dragover.MultiDraggableMixin': (event) => @renderDragFeedback(event.originalEvent)
        'dragend.MultiDraggableMixin': @removeDragFeedback

    onItemDragEnterOrOver: (event, callback) ->
      types = event.dataTransfer.types or []
      return unless 'Text' in types or 'text/plain' in types
      event.preventDefault()
      callback(event) if callback

    onItemDragLeaveOrEnd: (event, callback) ->
      types = event.dataTransfer.types or []
      return unless 'Text' in types or 'text/plain' in types
      callback(event) if callback

    onItemDrop: (event, destinationFolder, callback) ->
      return unless (event.dataTransfer.getData('Text') or event.dataTransfer.getData('text/plain')) is 'in_a_dndMixin_drag'
      event.preventDefault()
      moveStuff(@itemsToDrag(), destinationFolder).then(
        ->
          callback({success: true, event}) if callback
        , ->
          callback({success: false, event}) if callback
      ).done(@clearSelectedItems)
#      @clearSelectedItems()
#      callback(event) if callback
