define [
  'i18n!react_files'
  'react'
  'compiled/react/shared/utils/withReactElement'
], (I18n, React, withReactElement) ->

  NoResults = React.createClass

     displayName: 'NoResults'

     render: withReactElement ->
        div {},
          p {}, I18n.t('errors.no_match.your_search', 'Your search - "%{search_term}" - did not match any files.', {search_term: @props.search_term})
          p {}, I18n.t('errors.no_match.suggestions', 'Suggestions:')
          ul {},
            li {}, I18n.t('errors.no_match.spelled', 'Make sure all words are spelled correctly.')
            li {}, I18n.t('errors.no_match.keywords', 'Try different keywords.')
            li {}, I18n.t('errors.no_match.three_chars', 'Enter at least 3 letters in the search box.')