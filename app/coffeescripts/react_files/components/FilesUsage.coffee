define [
  'i18n!react_files'
  'react'
  'compiled/util/friendlyBytes'
  'compiled/react/shared/utils/withReactDOM'
  './ProgressBar'
  '../modules/customPropTypes'
  '../utils/toFixedDecimal'
], (I18n, React, friendlyBytes, withReactDOM, ProgressBar, customPropTypes, toFixedDecimal) ->

  FilesUsage = React.createClass
    displayName: 'FilesUsage'

    propTypes:
      contextType: customPropTypes.contextType.isRequired
      contextId: customPropTypes.contextId.isRequired

    update: ->
      $.get "/api/v1/#{@props.contextType}/#{@props.contextId}/files/quota", (data) =>
        @setState(data)

    componentDidMount: ->
      @update()
      @interval = setInterval @update, 1000*60*5 #refresh every 5 minutes

    componentWillUnmount: ->
      clearInterval @interval

    render: withReactDOM ->
      @transferPropsTo div {},
        if @state
          div className: 'grid-row ef-quota-usage',
            div className: 'col-xs',
              ProgressBar({
                progress: toFixedDecimal(@state.quota_used / @state.quota * 100, 2),
                'aria-label': I18n.t('Using %{percent}% of storage quota.',
                                    {percent: toFixedDecimal(@state.quota_used / @state.quota * 100, 2)})
              }),
            div className: 'col-xs-6', style: 'padding-left': '0px',
              I18n.t 'usage_details', '%{percent}% of %{quota} used',
                percent: Math.ceil(@state.quota_used / @state.quota * 100)
                quota: friendlyBytes(@state?.quota)

