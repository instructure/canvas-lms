define [
  'old_unsupported_dont_use_react'
  'compiled/react/shared/utils/withReactDOM'
], (React, withReactDOM) ->

  ProgressBar = React.createClass
    displayName: 'ProgressBar'

    propTypes:
      progress: React.PropTypes.number.isRequired
      'aria-label': React.PropTypes.string #Used as an override if needed.


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
          'aria-label': @props['aria-label'] if @props['aria-label']
          style:
            width: Math.min(@props.progress, 100) + '%'
