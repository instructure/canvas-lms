define [
  'i18n!react_files'
  'react'
  'compiled/util/friendlyBytes'
  'compiled/react/shared/utils/withReactDOM'
  './ProgressBar'
], (I18n, React, friendlyBytes, withReactDOM, ProgressBar) ->

  FilesUsage = React.createClass
    displayName: 'FilesUsage'

    propTypes:
      contextType: React.PropTypes.oneOf(['users', 'groups', 'accounts', 'courses']).isRequired
      contextId: React.PropTypes.string.isRequired

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
              ProgressBar({progress: @state.quota_used / @state.quota * 100}),
            div className: 'col-xs',
              I18n.t 'usage_details', '%{quota_used} of %{quota}',
                quota_used: friendlyBytes(@state?.quota_used)
                quota: friendlyBytes(@state?.quota)

