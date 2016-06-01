define([
  'react',
  'jsx/shared/DatetimeDisplay',
  'i18n!react_collaborations',
  'compiled/str/splitAssetString'
], (React, DatetimeDisplay, i18n, splitAssetString) => {
  class Collaboration extends React.Component {
    render () {
      let { collaboration } = this.props
      let [context, contextId] = splitAssetString(ENV.context_asset_string)

      return (
        <div className='Collaboration'>
          <div className='Collaboration-body'>
            <a
              className='Collaboration-title'
              href={`/${context}/${contextId}/collaborations/${collaboration.id}`}
            >
              {collaboration.title}
            </a>
            <p className='Collaboration-description'>{collaboration.description}</p>
            <a className='Collaboration-author' href={`/users/${collaboration.user_id}`}>{collaboration.user_name},</a>
            <DatetimeDisplay datetime={collaboration.updated_at} format='%b %d, %l:%M %p' />
          </div>
          <div className='Collaboration-actions'>
            <a className='icon-edit'>
              <span className='screenreader-only'>{i18n.t('Edit Collaboration')}</span>
            </a>
            <button className='btn btn-link'>
              <i className='icon-trash'></i>
              <span className='screenreader-only'>{i18n.t('Delete Collaboration')}</span>
            </button>
          </div>
        </div>
      );
    }
  };

  Collaboration.propTypes = {
    collaboration: React.PropTypes.object
  };

  return Collaboration
});
