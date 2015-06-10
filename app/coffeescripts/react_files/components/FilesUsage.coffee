define [
  'i18n!react_files'
  'react'
  'compiled/util/friendlyBytes'
  'compiled/react/shared/utils/withReactElement'
  './ProgressBar'
  '../modules/customPropTypes'
  '../utils/toFixedDecimal'
], (I18n, React, friendlyBytes, withReactElement, ProgressBarComponent, customPropTypes, toFixedDecimal) ->

  ProgressBar = React.createFactory ProgressBarComponent

  FilesUsage = React.createClass
    displayName: 'FilesUsage'
    url: ->
      "/api/v1/#{@props.contextType}/#{@props.contextId}/files/quota"

    propTypes:
      contextType: customPropTypes.contextType.isRequired
      contextId: customPropTypes.contextId.isRequired

    update: ->
      $.get @url(), (data) =>
        @setState(data)

    componentDidMount: ->
      @update()
      @interval = setInterval @update, 1000*60*5 #refresh every 5 minutes

    componentWillUnmount: ->
      clearInterval @interval

    render: withReactElement ->
      div {},
        if @state

          percentUsed = Math.round(@state.quota_used / @state.quota * 100)
          label = I18n.t('%{percentUsed}% of %{bytesAvailable} used', {
            percentUsed: percentUsed,
            bytesAvailable: friendlyBytes(@state.quota)
          })

          div className: 'grid-row ef-quota-usage',
            div className: 'col-xs-5',
              ProgressBar({
                progress: percentUsed,
                'aria-label': label
              }),
            div {
              className: 'col-xs-7'
              style: paddingLeft: '0px'
              'aria-hidden': true
            },
              label


