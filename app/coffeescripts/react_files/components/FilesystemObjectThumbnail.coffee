define [
  'react'
  '../mixins/BackboneMixin'
  'compiled/models/Folder'
  '../modules/customPropTypes'
  'compiled/util/mimeClass'
  'compiled/react/shared/utils/withReactElement'
], (React, BackboneMixin, Folder, customPropTypes, mimeClass, withReactElement) ->

  FilesystemObjectThumbnail = React.createClass
    displayName: 'FilesystemObjectThumbnail'

    propTypes:
      model: customPropTypes.filesystemObject

    mixins: [BackboneMixin('model')],

    render: withReactElement ->
      if @props.model.get('thumbnail_url')
        span
          className: "media-object ef-thumbnail FilesystemObjectThumbnail #{(@props.className if @props.className?)}"
          style:
            backgroundImage: "url('#{ @props.model.get('thumbnail_url') }')"
      else
        className = if @props.model instanceof Folder
          'folder'
        else
          mimeClass(@props.model.get('content-type'))
        i className: "media-object ef-big-icon FilesystemObjectThumbnail mimeClass-#{className} #{@props.className if @props.className?}"
