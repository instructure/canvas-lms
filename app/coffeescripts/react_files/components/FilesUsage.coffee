define [
  'i18n!react_files'
  'react'
  'compiled/util/friendlyBytes'
], (I18n, React, friendlyBytes) ->

  FilesUsage = React.createClass

    propTypes:
      contextType: React.PropTypes.oneOf(['users', 'groups', 'accounts', 'courses']).isRequired
      contextId: React.PropTypes.string.isRequired

    update: ->
      $.get "/api/v1/#{@props.contextType}/#{@props.contextId}/files/quota", (data) =>
        @setState(data)

    componentDidMount: ->
      @update()
      setInterval @update, 1000*60*5 #refresh every 5 minutes

    render: ->
      text = I18n.t('usage_details', '%{quota_used} of %{quota}', {
        quota_used: friendlyBytes(@state?.quota_used),
        quota: friendlyBytes(@state?.quota)
      })
      React.DOM.div className:"ef-folder-totals", text