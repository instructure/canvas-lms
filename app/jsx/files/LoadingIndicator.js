import I18n from 'i18n!react_files'
import React from 'react'

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

export default LoadingIndicator
