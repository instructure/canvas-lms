define [
  'i18n!react_files'
  'old_unsupported_dont_use_react'
  'compiled/util/friendlyBytes'
  'compiled/react/shared/utils/withReactDOM'
  './ProgressBar'
  '../modules/customPropTypes'
  '../utils/toFixedDecimal'
], (I18n, React, friendlyBytes, withReactDOM, ProgressBar, customPropTypes, toFixedDecimal) ->

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

    render: withReactDOM ->
      @transferPropsTo div {},
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
              style: 'padding-left': '0px'
              'aria-hidden': true
            },
              label


