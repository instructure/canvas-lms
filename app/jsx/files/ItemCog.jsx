define([
  'i18n!react_files',
  'react',
  'react-dom',
  'compiled/fn/preventDefault',
  'compiled/react_files/modules/customPropTypes',
  'compiled/react_files/modules/filesEnv',
  'compiled/models/File',
  'compiled/models/Folder',
  'jsx/files/UsageRightsDialog',
  'jsx/files/RestrictedDialogForm',
  'jsx/files/utils/openMoveDialog',
  'compiled/react_files/utils/downloadStuffAsAZip',
  'compiled/react_files/utils/deleteStuff',
  'jquery'
], function (I18n, React, ReactDOM, preventDefault, customPropTypes, filesEnv, File, Folder, UsageRightsDialog, RestrictedDialogForm, openMoveDialog, downloadStuffAsAZip, deleteStuff, $) {

  var ItemCog = React.createClass({
    displayName: 'ItemCog',

    propTypes: {
      model: customPropTypes.filesystemObject,
      modalOptions: React.PropTypes.object.isRequired,
      externalToolsForContext: React.PropTypes.arrayOf(React.PropTypes.object),
      userCanManageFilesForContext: React.PropTypes.bool,
      usageRightsRequiredForContext: React.PropTypes.bool
    },

    downloadFile (file, args) {
      window.location = file[0].get('url');
      $(args.returnFocusTo).focus();
    },

    downloadZip (folder, args) {
      downloadStuffAsAZip(folder, args);
      $(args.returnFocusTo).focus();
    },

    deleteItem (item, args) {
      // Unfortunately, ars.returnFocusTo isn't really the one we want to focus,
      // because we want the previous one or the +Folder button
      // Also unfortunately, our state management in this app is a bit terrible
      // so we'll just handle all that via jQuery right here for now.
      // TODO: Make this less terrible when we have sane state management
      const allTriggers = $('.al-trigger').toArray();
      const hasMoreTriggers = allTriggers.length - 1 > 0;
      const toFocus = (hasMoreTriggers) ?
                      allTriggers[allTriggers.indexOf(args.returnFocusTo) - 1] :
                      $('.ef-name-col a').first();
      args.returnFocusTo = toFocus;
      deleteStuff(item, args);
    },

    openUsageRightsDialog (event) {
      var contents = (
        <UsageRightsDialog
          closeModal={this.props.modalOptions.closeModal}
          itemsToManage={[this.props.model]}
        />
      );

      this.props.modalOptions.openModal(contents, () => {
        ReactDOM.findDOMNode(this.refs.settingsCogBtn).focus();
      });
    },

    render () {
      var externalToolMenuItems;
      if (this.props.model instanceof File) {
        externalToolMenuItems = this.props.externalToolsForContext.map((tool) => {
          if (this.props.model.externalToolEnabled(tool)) {
            return (
              <li key={tool.title} role='presentation'>
                <a href={`${tool.base_url}&files[]=${this.props.model.id}`} role='menuitem' tabIndex='-1'>
                  {tool.title}
                </a>
              </li>
            );
          } else {
            return (<li key={tool.title} role='presentation'><a href='#' className='disabled' role='menuitem' tabIndex='-1' aria-disabled='true'>{tool.title}</a></li>);
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
            returnFocusTo: ReactDOM.findDOMNode(this.refs.settingsCogBtn)
          };

          args = $.extend(args, params);
          return fn([this.props.model], args);

        });
      };

      var menuItems = [];

      // Download Link
      if (this.props.model instanceof Folder) {
        menuItems.push(<li key='folderDownload' role='presentation'><a href='#' onClick={wrap(this.downloadZip)} ref='download' role='menuitem' tabIndex='-1'>{I18n.t('Download')}</a></li>);
      } else {
        menuItems.push(<li key='download' role='presentation'><a onClick={wrap(this.downloadFile)} href={this.props.model.get('url')} ref='download' role='menuitem' tabIndex='-1'>{I18n.t('Download')}</a></li>);
      }

      if (this.props.userCanManageFilesForContext) {
        // Rename Link
        menuItems.push(<li key='rename' role='presentation'><a href='#' onClick={preventDefault(this.props.startEditingName)} ref='editName' role='menuitem' tabIndex='-1'>{I18n.t('Rename')}</a></li>);
        // Move Link
        menuItems.push(<li key='move' role='presentation'><a href='#' onClick={wrap(openMoveDialog, {clearSelectedItems: this.props.clearSelectedItems, onMove: this.props.onMove})} ref='move' role='menuitem' tabIndex='-1'>{I18n.t('Move')}</a></li>);

        if (this.props.usageRightsRequiredForContext) {
          // Manage Usage Rights Link
          menuItems.push(<li key='manageUsageRights' className='ItemCog__OpenUsageRights' role='presentation'><a href='#' onClick={preventDefault(this.openUsageRightsDialog)} ref='usageRights' role='menuitem' tabIndex='-1'>{I18n.t('Manage Usage Rights')}</a></li>);
        }

        // Delete Link
        menuItems.push(<li key='delete' role='presentation'><a href='#' onClick={wrap(this.deleteItem)} ref='deleteLink' role='menuitem' tabIndex='-1'>{I18n.t('Delete')}</a></li>);
      }

      return (
        <div className='al-dropdown__container' style={{minWidth: '45px', display: 'inline-block'}}>
          <button
            type='button'
            ref='settingsCogBtn'
            className='al-trigger al-trigger-gray btn btn-link'
            aria-label={I18n.t('Actions')}
            data-popup-within='#application'
            data-append-to-body={true}
          >
            <i className='icon-settings' />
            <i className='icon-mini-arrow-down' />
          </button>
          <ul className='al-options' role='menu' aria-hidden='true' aria-expanded='false' tabIndex='0'>
            {menuItems.concat(externalToolMenuItems)}
          </ul>
        </div>
      );
    }

  });

  return ItemCog;
});
