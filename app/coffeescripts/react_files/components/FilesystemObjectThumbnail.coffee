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

    getInitialState: ->
      thumbnail_url: @props.model?.get('thumbnail_url')

    componentDidMount: ->
      # Set an interval to check for thumbnails
      # if they don't currently exist (e.g. when
      # a thumbnail is being generated but not
      # immediately available after file upload)
      intervalMultiplier = 1.5
      delay = 2000
      attempts = 0
      maxAttempts = 10

      checkThumbnailTimeout = =>
        delay *= intervalMultiplier
        attempts++

        setTimeout =>
          @checkForThumbnail()
          return clearTimeout(checkThumbnailTimeout) if attempts >= maxAttempts
          checkThumbnailTimeout()
        , delay

      checkThumbnailTimeout()

    checkForThumbnail: ->
      return if @state.thumbnail_url or
                @props.model?.attributes?.locked_for_user or
                @props.model instanceof Folder or
                @props.model?.get('content-type')?.match("audio")

      @props.model?.fetch success: (model, response, options) =>
        @setState(thumbnail_url: response.thumbnail_url) if response?.thumbnail_url

    render: withReactElement ->
      if @state.thumbnail_url
        span
          className: "media-object ef-thumbnail FilesystemObjectThumbnail #{(@props.className if @props.className?)}"
          style:
            backgroundImage: "url('#{ @state.thumbnail_url }')"
      else
        className = if @props.model instanceof Folder
          'folder'
        else
          mimeClass(@props.model.get('content-type'))
        i className: "media-object ef-big-icon FilesystemObjectThumbnail mimeClass-#{className} #{@props.className if @props.className?}"
