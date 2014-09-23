define [
  'i18n!upload_drop_zone'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/FileOptionsCollection'
  'compiled/models/Folder'
], (I18n, React, withReactDOM, FileOptionsCollection, Folder) ->

  UploadDropZone = React.createClass

    displayName: 'UploadDropZone'

    propTypes:
      currentFolder: React.PropTypes.instanceOf(Folder)

    getInitialState: ->
      active: false

    componentDidMount: ->
      @getParent().addEventListener('dragenter', @onParentDragEnter)
      document.addEventListener('dragenter', @killWindowDropDisplay)
      document.addEventListener('dragover', @killWindowDropDisplay)
      document.addEventListener('drop', @killWindowDrop)

    componentWillUnmount: ->
      @getParent().removeEventListener('dragenter', @onParentDragEnter)
      document.removeEventListener('dragenter', @killWindowDropDisplay)
      document.removeEventListener('dragover', @killWindowDropDisplay)
      document.removeEventListener('drop', @killWindowDrop)

    onDragEnter: (e) ->
      if @shouldAcceptDrop(e.dataTransfer.types)
        if !this.state.active
          @setState({active: true})
        e.dataTransfer.dropEffect = 'copy'
        e.preventDefault()
        e.stopPropagation() # keep event from getting to document
        false
      else
        true

    onDragLeave: (e) ->
      @setState({active: false})

    onDrop: (e) ->
      FileOptionsCollection.setFolder(@props.currentFolder)
      FileOptionsCollection.setOptionsFromFiles(e.dataTransfer.files, true)
      @setState({active: false})
      e.preventDefault()
      e.stopPropagation()
      false

    # when you drag a file over the parent, make drop zone active
    # remainder of drag-n-drop events happen on dropzone
    onParentDragEnter: (e)->
      if @shouldAcceptDrop(e.dataTransfer.types)
        if !this.state.active
          @setState({active: true})

    killWindowDropDisplay: (e) ->
      if e.target != @getParent()
        e.preventDefault()

    killWindowDrop: (e) ->
      e.preventDefault()

    shouldAcceptDrop: (types) ->
      # event.dataTransfer.types doesn't respond to array methods in Firefox like
      # the other browsers even though it has length, and array access?
      i = 0
      found = false
      while i<types.length
        type = types[i]
        found = (type == 'Files')
        if (found)
          break
        i++
      found

    getParent: ->
      @getDOMNode().parentElement

    buildNonActiveDropZone: ->
      div
        className: 'UploadDropZone',
          ''

    buildInstructions: ->
      div className: 'UploadDropZone__instructions',
        i className: 'icon-upload UploadDropZone__instructions--icon-upload'
        div {},
          p className: 'UploadDropZone__instructions--drag',
            I18n.t('drop_to_upload', 'Drop items to upload')

    buildDropZone: ->
      div
        className: 'UploadDropZone UploadDropZone__active'
        onDrop: this.onDrop
        onDragLeave: this.onDragLeave
        onDragOver: this.onDragEnter
        onDragEnter: this.onDragEnter,
          @buildInstructions()

    render: withReactDOM ->
      if @state.active
        @buildDropZone()
      else
        @buildNonActiveDropZone()
