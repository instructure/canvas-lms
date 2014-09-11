define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
], (React, withReactDOM) ->

  ProgressBar = React.createClass

    propTypes:
      progress: React.PropTypes.number

    createWidthStyle: ->
      width: @props.progress + '%'

    render: withReactDOM ->
      almostDone = ''
      almostDone = ' almost-done' if @props.progress == 100
      div ref: 'container', className: 'progress-bar__bar-container' + almostDone,
        div
          ref: 'bar'
          className: 'progress-bar__bar' + almostDone
          role: 'progressbar'
          'aria-valuenow': @props.progress
          'aria-valuemin': 0
          'aria-valuemax': 100
          style: @createWidthStyle()
