define [
  'i18n!react_files'
  'old_unsupported_dont_use_react'
  'compiled/react/shared/utils/withReactDOM'
], (I18n, React, withReactDOM) ->

  NoResults = React.createClass

     displayName: 'NoResults'

     render: withReactDOM ->
        div {},
          p {}, I18n.t('errors.no_match.your_search', 'Your search - "%{search_term}" - did not match any files.', {search_term: @props.search_term})
          p {}, I18n.t('errors.no_match.suggestions', 'Suggestions:')
          ul {},
            li {}, I18n.t('errors.no_match.spelled', 'Make sure all words are spelled correctly.')
            li {}, I18n.t('errors.no_match.keywords', 'Try different keywords.')
            li {}, I18n.t('errors.no_match.three_chars', 'Enter at least 3 letters in the search box.')