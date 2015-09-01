/* @jsx React.DOM */

define([
  'react',
  'i18n!file_preview',
  'jsx/files/FriendlyDatetime',
  'compiled/util/friendlyBytes',
  'compiled/react/shared/utils/withReactElement',
  'compiled/react_files/modules/customPropTypes',
  'compiled/react_files/utils/getFileStatus',
  'compiled/util/mimeClass'
 ], function (React, I18n, FriendlyDatetime, friendlyBytes, withReactElement, customPropTypes, getFileStatus, mimeClass) {

  var FilePreviewInfoPanel = React.createClass({
    displayName: 'FilePreviewInfoPanel',

    propTypes: {
      displayedItem: customPropTypes.filesystemObject.isRequired,
      usageRightsRequiredForContext: React.PropTypes.bool
    },

    render () {
      return (
        <div className='ef-file-preview-information-container'>
          <table className='ef-file-preview-infotable'>
            <tbody>
              <tr>
                <th scope='row'>{I18n.t('Name')}</th>
                <td ref='displayName'>{this.props.displayedItem.displayName()}</td>
              </tr>
              <tr>
                <th scope='row'>{I18n.t('Status')}</th>
                <td ref='status'>{getFileStatus(this.props.displayedItem)}</td>
              </tr>
              <tr>
                <th scope='row'>{I18n.t('Kind')}</th>
                <td ref='contentType'>{mimeClass.displayName(this.props.displayedItem.get('content-type'))}</td>
              </tr>
              <tr>
                <th scope='row'>{I18n.t('Size')}</th>
                <td ref='size'>{friendlyBytes(this.props.displayedItem.get('size'))}</td>
              </tr>
              <tr>
                <th scope='row'>{I18n.t('Date Modified')}</th>
                <td id='dateModified' ref='dateModified'><FriendlyDatetime datetime={this.props.displayedItem.get('updated_at')} /></td>
              </tr>
              {this.props.displayedItem.get('user') && (
                <tr>
                  <th scope='row'>{I18n.t('Last Modified By')}</th>
                  <td ref='modifedBy'>
                    <a href={this.props.displayedItem.get('user').html_url}>{this.props.displayedItem.get('user').display_name}</a>
                  </td>
                </tr>
              )}
              <tr>
                <th scope='row'>{I18n.t('Date Created')}</th>
                <td id= 'dateCreated'><FriendlyDatetime datetime={this.props.displayedItem.get('created_at')} /></td>
              </tr>
              {this.props.usageRightsRequiredForContext && (
                <tr className='FilePreviewInfoPanel__usageRights'>
                  <th scope='row'>{I18n.t('Usage Rights')}</th>
                  <td>
                    {this.props.displayedItem && this.props.displayedItem.get('usage_rights') && this.props.displayedItem.get('usage_rights').license_name && (
                      <div ref='licenseName'>{this.props.displayedItem.get('usage_rights').license_name}</div>
                    )}
                    {this.props.displayedItem && this.props.displayedItem.get('usage_rights') && this.props.displayedItem.get('usage_rights').legal_copyright && (
                      <div ref='legalCopyright'>{this.props.displayedItem.get('usage_rights').legal_copyright}</div>
                    )}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      );
    }

  });

  return FilePreviewInfoPanel;

});
