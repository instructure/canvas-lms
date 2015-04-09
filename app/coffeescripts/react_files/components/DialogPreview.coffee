define [
  'i18n!react_files'
  'react'
  '../modules/customPropTypes'
  'compiled/models/Folder'
  '../modules/filesEnv'
  './FilesystemObjectThumbnail'
  'compiled/react/shared/utils/withReactElement'
], (I18n, React, customPropTypes, Folder, filesEnv, FilesystemObjectThumbnailComponent, withReactElement) ->

  MAX_THUMBNAILS_TO_SHOW = 5
  FilesystemObjectThumbnail = React.createFactory FilesystemObjectThumbnailComponent

  #####
  # This is used to show a preview inside of a modal dialog.
  #####
  DialogPreview = React.createClass
    displayName: 'DialogPreview'

    propTypes:
      itemsToShow: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired

    renderPreview: ->
      if @props.itemsToShow.length == 1
        FilesystemObjectThumbnail({
          model: @props.itemsToShow[0]
          className: 'DialogPreview__thumbnail'
        })
      else
        @props.itemsToShow.slice(0, MAX_THUMBNAILS_TO_SHOW).map (model, index) =>
          i {
            className: 'media-object ef-big-icon FilesystemObjectThumbnail mimeClass-file DialogPreview__thumbnail'
            style:
              left: 10 * index
              top: -140 * index
          }

    render: withReactElement ->
      div {className: 'DialogPreview__container'},
        @renderPreview()
