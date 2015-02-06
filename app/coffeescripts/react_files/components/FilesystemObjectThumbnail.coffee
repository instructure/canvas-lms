define [
  'react'
  '../mixins/BackboneMixin'
  'compiled/models/Folder'
  '../modules/customPropTypes'
  'compiled/util/mimeClass'
], (React, BackboneMixin, Folder, customPropTypes, mimeClass) ->

  DOM = React.DOM


  FilesystemObjectThumbnail = React.createClass
    displayName: 'FilesystemObjectThumbnail'

    propTypes:
      model: customPropTypes.filesystemObject

    mixins: [BackboneMixin('model')],

    render: ->
      @transferPropsTo if @props.model.get('thumbnail_url')
          DOM.span
            className: 'media-object ef-thumbnail FilesystemObjectThumbnail'
            style:
              backgroundImage: "url('#{ @props.model.get('thumbnail_url') }')"
        else
          className = if @props.model instanceof Folder
            'folder'
          else
            mimeClass(@props.model.get('content-type'))
          DOM.i className:'media-object ef-big-icon FilesystemObjectThumbnail mimeClass-' + className