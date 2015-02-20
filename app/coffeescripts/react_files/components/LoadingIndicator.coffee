define [
  'i18n!react_files'
  'old_unsupported_dont_use_react'
], (I18n, React) ->

  LoadingIndicator = React.createClass
    displayName: 'LoadingIndicator'

    render: ->
      style = {}
      style.display = 'none' unless @props.isLoading
      React.DOM.div style: style, className:'paginatedView-loading', role: 'status', 'aria-live':'polite',
        I18n.t 'loading_more_results', 'Loading more results...'