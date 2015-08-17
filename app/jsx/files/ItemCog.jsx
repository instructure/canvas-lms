define([
  'i18n!react_files',
  'react',
  'compiled/fn/preventDefault',
  'compiled/react_files/modules/customPropTypes',
  'compiled/react_files/modules/filesEnv',
  'compiled/models/File',
  'compiled/models/Folder',
  'jsx/files/UsageRightsDialog',
  'jsx/files/RestrictedDialogForm',
  'compiled/react_files/utils/openMoveDialog',
  'compiled/react_files/utils/downloadStuffAsAZip',
  'compiled/react_files/utils/deleteStuff',
  'jquery'
], function (I18n, React, preventDefault, customPropTypes, filesEnv, File, Folder, UsageRightsDialog, RestrictedDialogForm, openMoveDialog, downloadStuffAsAZip, deleteStuff, $) {

  var ItemCog = React.createClass({
    displayName: 'ItemCog',

    propTypes: {
      model: customPropTypes.filesystemObject,
      modalOptions: React.PropTypes.object.isRequired,
      externalToolsForContext: React.PropTypes.arrayOf(React.PropTypes.object),
      userCanManageFilesForContext: React.PropTypes.bool,
      usageRightsRequiredForContext: React.PropTypes.bool
    },

    openUsageRightsDialog (event) {
      var contents = (
        <UsageRightsDialog
          closeModal={this.props.modalOptions.closeModal}
          itemsToManage={[this.props.model]}
        />
      );

      this.props.modalOptions.openModal(contents, () => {
        this.refs.settingsCogBtn.getDOMNode().focus();
      });
    },

    render () {
      var externalToolMenuItems;
      if (this.props.model instanceof File) {
        externalToolMenuItems = this.props.externalToolsForContext.map((tool) => {
          if (this.props.model.externalToolEnabled(tool)) {
            return (
              <li>
                <a href={`${tool.base_url}&files[]=${this.props.model.id}`}>
                  {tool.title}
                </a>
              </li>
            );
          } else {
            return (<li><a href='#' className='disabled'>{tool.title}</a></li>);
          }
        });
      } else {
        externalToolMenuItems = [];
      }

      var wrap = (fn, params = {}) => {
        return preventDefault((event) => {
          var singularContextType = (this.props.model.collection && this.props.model.collection.parentFolder) ?
                                    this.props.model.collection.parentFolder.get('context_type').toLowerCase() : null;
          var pluralContextType = (singularContextType) ? singularContextType + 's' : null
          var contextType = pluralContextType || filesEnv.contextType;
          var contextId = (this.props.model.collection && this.props.model.collection.parentFolder) ?
                          this.props.model.collection.parentFolder.get('context_id') : filesEnv.contextId;
          var args = {
            contextType,
            contextId,
            returnFocusTo: this.refs.settingsCogBtn.getDOMNode()
          };

          args = $.extend(args, params);
          return fn([this.props.model], args);

        });
      };

      var menuItems = [];

      // Download Link
      if (this.props.model instanceof Folder) {
        menuItems.push(<li><a href='#' onClick={wrap(downloadStuffAsAZip)} ref='download'>{I18n.t('Download')}</a></li>);
      } else {
        menuItems.push(<li><a href={this.props.model.get('url')} ref='download'>{I18n.t('Download')}</a></li>);
      }

      if (this.props.userCanManageFilesForContext) {
        // Rename Link
        menuItems.push(<li><a href='#' onClick={preventDefault(this.props.startEditingName)} ref='editName'>{I18n.t('Rename')}</a></li>);
        // Move Link
        menuItems.push(<li><a href='#' onClick={wrap(openMoveDialog, {clearSelectedItems: this.props.clearSelectedItems})} ref='move'>{I18n.t('Move')}</a></li>);

        if (this.props.usageRightsRequiredForContext) {
          // Manage Usage Rights Link
          menuItems.push(<li className='ItemCog__OpenUsageRights'><a href='#' onClick={preventDefault(this.openUsageRightsDialog)} ref='usageRights'>{I18n.t('Manage Usage Rights')}</a></li>);
        }

        // Delete Link
        menuItems.push(<li><a href='#' onClick={wrap(deleteStuff)} ref='deleteLink'>{I18n.t('Delete')}</a></li>);
      }

      return (
        <span style={{minWidth: '45px'}}>
          <button
            type='button'
            ref='settingsCogBtn'
            className='al-trigger al-trigger-gray btn btn-link'
            aria-label={I18n.t('Actions')}
            data-popup-within='#wrapper'
            data-append-to-body={true}
          >
            <i className='icon-settings' />
            <i className='icon-mini-arrow-down' />
          </button>
          <ul className='al-options'>
            {menuItems.concat(externalToolMenuItems)}
          </ul>
        </span>
      );
    }

  });

  return ItemCog;
});