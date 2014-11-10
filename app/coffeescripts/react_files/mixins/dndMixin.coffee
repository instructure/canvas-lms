define [
  'i18n!react_files'
  'react'
  '../components/DragFeedback'
  '../utils/moveStuff'
  'compiled/models/Folder'
  'jquery'
], (I18n, React, DragFeedback, moveStuff, Folder, $) ->

  dndMixin =

    itemsToDrag: -> @state.selectedItems

    renderDragFeedback: ({pageX, pageY}) ->
      @dragHolder ||= $('<div>').appendTo(document.body)
      React.renderComponent(DragFeedback({
        pageX: pageX
        pageY: pageY
        itemsToDrag: @itemsToDrag()
      }), @dragHolder[0])

    removeDragFeedback: ->
      $(document).off('.MultiDraggableMixin')
      React.unmountComponentAtNode(@dragHolder[0]) if @dragHolder
      @dragHolder = null

    onItemDragStart: (event) ->
      itemsToDrag = @itemsToDrag()
      event.dataTransfer.effectAllowed = 'move'
      event.dataTransfer.setData('canvaslms/custom-dnd-move', true)

      # make it so you can drag stuff to other apps and it will at least copy a list of urls
      # see: https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Recommended_Drag_Types#link
      event.dataTransfer.setData('text/uri-list', itemsToDrag.map((item) -> item.get('url')).join('\n'))

      # replace the default ghost dragging element with a transparent gif
      # since we are going to use our own custom drag image
      img = new Image
      img.src = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
      event.dataTransfer.setDragImage(img, 150, 150)

      @renderDragFeedback(event)

      $(document).on
        'dragover.MultiDraggableMixin': (event) => @renderDragFeedback(event.originalEvent)
        'dragend.MultiDraggableMixin': @removeDragFeedback

    onItemDragEnterOrOver: (event, callback) ->
      return unless 'canvaslms/custom-dnd-move' in event.dataTransfer.types
      event.preventDefault()
      callback(event) if callback

    onItemDragLeaveOrEnd: (event, callback) ->
      return unless 'canvaslms/custom-dnd-move' in event.dataTransfer.types
      callback(event) if callback

    onItemDrop: (event, destinationFolder, callback) ->
      return unless 'canvaslms/custom-dnd-move' in event.dataTransfer.types
      event.preventDefault()
      moveStuff(@itemsToDrag(), destinationFolder)
      @clearSelectedItems()
      callback(event) if callback

