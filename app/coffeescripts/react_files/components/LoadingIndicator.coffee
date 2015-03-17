define [
  'i18n!react_files'
  'react'
  'compiled/react/shared/utils/withReactElement'
], (I18n, React, withReactElement) ->

  LoadingIndicator = React.createClass
    displayName: 'LoadingIndicator'

    render: withReactElement ->
      style = {}
      style.display = 'none' unless @props.isLoading
      div style: style, className:'paginatedView-loading', role: 'status', 'aria-live':'polite',
        I18n.t 'loading_more_results', 'Loading more results...'