define([
  'i18n!react_files',
  'react'
], function (I18n, React) {

  var NoResults = React.createClass({
    displayName: 'NoResults',

    propTypes: {
      search_term: React.PropTypes.string
    },

    render: function () {
      return (
        <div>
          <p ref='yourSearch'>
            {I18n.t('errors.no_match.your_search', 'Your search - "%{search_term}" - did not match any files.', {search_term: this.props.search_term})}
          </p>
          <p>{I18n.t('errors.no_match.suggestions', 'Suggestions:')}</p>
          <ul>
            <li>{I18n.t('errors.no_match.spelled', 'Make sure all words are spelled correctly.')}</li>
            <li>{I18n.t('errors.no_match.keywords', 'Try different keywords.')}</li>
            <li>{I18n.t('errors.no_match.three_chars', 'Enter at least 3 letters in the search box.')}</li>
          </ul>
        </div>
      );
    }

  });

  return NoResults;
});
