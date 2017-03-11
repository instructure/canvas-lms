define([
  'jquery',
  'react',
  'react-modal',
  'page',
  'compiled/react_files/components/FilesApp',
  'compiled/react_files/modules/filesEnv',
  'i18n!react_files',
  'jsx/files/Breadcrumbs',
  'jsx/files/FolderTree',
  'jsx/files/FilesUsage',
  'jsx/files/Toolbar'
], function ($, React, ReactModal, page, FilesApp, filesEnv, I18n, Breadcrumbs, FolderTree, FilesUsage, Toolbar) {

  const modalOverrides = {
    overlay : {
      backgroundColor: 'rgba(0,0,0,0.5)'
    },
    content : {
      position: 'static',
      top: '0',
      left: '0',
      right: 'auto',
      bottom: 'auto',
      borderRadius: '0',
      border: 'none',
      padding: '0'
    }
  };

  FilesApp.previewItem = function (item) {
    this.clearSelectedItems(() => {
      this.toggleItemSelected(item, null, () => {
        const queryString = $.param(this.getPreviewQuery());
        page(`${this.getPreviewRoute()}?${queryString}`);
      });
    });
  };

  FilesApp.getPreviewRoute = function () {
    if (this.props.query && this.props.query.search_term) {
      return '/search';
    } else if (this.props.splat) {
      return `/folder/${this.props.splat}`;
    } else {
      return '';
    }
  };

  FilesApp.render = function () {
    var contextType;
    var contextId;

    // when showing a folder
    if (this.state.currentFolder) {
      contextType = this.state.currentFolder.get('context_type').toLowerCase() + 's';
      contextId = this.state.currentFolder.get('context_id');
    } else {
      // when showing search results
      contextType = filesEnv.contextType;
      contextId = filesEnv.contextId;
    }

    var userCanManageFilesForContext = filesEnv.userHasPermission({contextType: contextType, contextId: contextId}, 'manage_files');
    var userCanRestrictFilesForContext = userCanManageFilesForContext && contextType != "groups";
    var usageRightsRequiredForContext = (filesEnv.contextsDictionary[`${contextType}_${contextId}`]) ?
                                         filesEnv.contextsDictionary[`${contextType}_${contextId}`].usage_rights_required : false;
    var externalToolsForContext = (filesEnv.contextFor({contextType: contextType, contextId: contextId})) ?
                                  filesEnv.contextFor({contextType: contextType, contextId: contextId}).file_menu_tools : [];

    return (
      <div>
        {/* For whatever reason, VO in Safari didn't like just the h1 tag.
            Sometimes it worked, others it didn't, this makes it work always */}
        <header>
          <h1 className='screenreader-only'>
            {I18n.t('Files')}
          </h1>
        </header>
        <div className='ic-app-nav-toggle-and-crumbs ic-app-nav-toggle-and-crumbs--files no-print'>
          <button
            className='Button Button--link Button--small ic-app-course-nav-toggle'
            type='button'
            id='courseMenuToggle'
            title={I18n.t("Show and hide courses menu")}
            aria-hidden={true}
          >
            <i className='icon-hamburger' />
          </button>
          <div className='ic-app-crumbs'>
            <Breadcrumbs
              rootTillCurrentFolder={this.state.rootTillCurrentFolder}
              showingSearchResults={this.state.showingSearchResults}
              query={this.props.query}
              contextAssetString={this.props.contextAssetString}
            />
          </div>
        </div>
        <Toolbar
          currentFolder={this.state.currentFolder}
          query={this.props.query}
          selectedItems={this.state.selectedItems}
          clearSelectedItems={this.clearSelectedItems}
          onMove={this.onMove}
          contextType={contextType}
          contextId={contextId}
          userCanManageFilesForContext={userCanManageFilesForContext}
          usageRightsRequiredForContext={usageRightsRequiredForContext}
          userCanRestrictFilesForContext={userCanRestrictFilesForContext}
          getPreviewQuery={this.getPreviewQuery}
          getPreviewRoute={this.getPreviewRoute}
          modalOptions={{
            openModal: this.openModal,
            closeModal: this.closeModal
          }}
        />
        <div className='ef-main'>
          {filesEnv.newFolderTree && (
            <p>New folder tree goes here</p>
          )}
          {!filesEnv.newFolderTree && (
            <aside
              className='visible-desktop ef-folder-content'
              role='region'
              aria-label={I18n.t('Folder Browsing Tree')}
            >
              <FolderTree
                rootTillCurrentFolder={this.state.rootTillCurrentFolder}
                rootFoldersToShow={filesEnv.rootFolders}
                dndOptions={{
                  onItemDragEnterOrOver: this.onItemDragEnterOrOver,
                  onItemDragLeaveOrEnd: this.onItemDragLeaveOrEnd,
                  onItemDrop: this.onItemDrop
                }}
              />
            </aside>
          )}
          <div
            className='ef-directory'
            role='region'
            aria-label={I18n.t('File List')}
          >
            {React.cloneElement(this.props.children, {
              key: this.state.key,
              pathname: this.props.pathname,
              splat: this.props.splat,
              query: this.props.query,
              params: this.props.params,
              onResolvePath: this.onResolvePath,
              currentFolder: this.state.currentFolder,
              contextType: contextType,
              contextId: contextId,
              selectedItems: this.state.selectedItems,
              toggleItemSelected: this.toggleItemSelected,
              toggleAllSelected: this.toggleAllSelected,
              areAllItemsSelected: this.areAllItemsSelected,
              userCanManageFilesForContext: userCanManageFilesForContext,
              userCanRestrictFilesForContext: userCanRestrictFilesForContext,
              usageRightsRequiredForContext: usageRightsRequiredForContext,
              externalToolsForContext: externalToolsForContext,
              previewItem: this.previewItem,
              onMove: this.onMove,
              modalOptions: {
                openModal: this.openModal,
                closeModal: this.closeModal
              },
              dndOptions: {
                onItemDragStart: this.onItemDragStart,
                onItemDragEnterOrOver: this.onItemDragEnterOrOver,
                onItemDragLeaveOrEnd: this.onItemDragLeaveOrEnd,
                onItemDrop: this.onItemDrop
              },
              clearSelectedItems: this.clearSelectedItems
            })}
          </div>
        </div>
        <div className='ef-footer grid-row'>
          {userCanManageFilesForContext && (
            <FilesUsage
              className='col-xs-4'
              contextType={contextType}
              contextId={contextId}
            />
          )}
          {(!filesEnv.showingAllContexts) && (
            <div className='col-xs'>
              <div>
                <a className='pull-right' href='/files'>
                  {I18n.t('All My Files')}
                </a>
              </div>
            </div>
          )}
        </div>
        {this.state.showingModal && (
          <ReactModal
            isOpen={this.state.showingModal}
            onRequestClose={this.closeModal}
            closeTimeoutMS={10}
            className='ReactModal__Content--canvas'
            overlayClassName='ReactModal__Overlay--canvas'
            style={modalOverrides}
          >
            {this.state.modalContents}
          </ReactModal>
        )}
      </div>
    );
  };

  return React.createClass(FilesApp);
});
