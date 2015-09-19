define([
  'i18n!react_files',
  'react'
], function (I18n, React, withReactElement) {

  var LoadingIndicator = React.createClass({
    displayName: 'LoadingIndicator',

    render () {
      var style = {
        display: (this.props.isLoading) ? '' : 'none'
      };

      return (
        <div style={style} className='paginatedView-loading' role='status' aria-live='polite'>
          {I18n.t('Loading more results...')}
        </div>
      );
    }
  });

  return LoadingIndicator;

});
