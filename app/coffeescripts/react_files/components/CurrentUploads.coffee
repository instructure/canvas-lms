define [
  'react'
  '../modules/UploadQueue'
], (React, UploadQueue) ->

  CurrentUploads =
    displayName: 'CurrentUploads'

    getInitialState: ->
      currentUploads: []

    componentWillMount: ->
      UploadQueue.onChange = =>
        @setState(currentUploads: UploadQueue.getAllUploaders())

    componentWillUnmount: ->
      UploadQueue.onChange = -> #noop

