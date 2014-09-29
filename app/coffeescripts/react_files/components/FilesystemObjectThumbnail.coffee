define [
  'react'
  '../mixins/BackboneMixin'
  'compiled/models/Folder'
  '../modules/customPropTypes'
], (React, BackboneMixin, Folder, customPropTypes) ->

  DOM = React.DOM


  FilesystemObjectThumbnail = React.createClass
    displayName: 'FilesystemObjectThumbnail'

    propTypes:
      model: customPropTypes.filesystemObject

    mixins: [BackboneMixin('model')],

    render: ->
      @transferPropsTo if @props.model instanceof Folder
          DOM.i className: 'icon-folder media-object ef-big-icon FilesystemObjectThumbnail'
        else if @props.model.get('thumbnail_url')
          DOM.span
            className: 'media-object ef-thumbnail FilesystemObjectThumbnail'
            style:
              backgroundImage: "url('#{ @props.model.get('thumbnail_url') }')"
        else
          DOM.i className:'icon-document media-object ef-big-icon FilesystemObjectThumbnail'