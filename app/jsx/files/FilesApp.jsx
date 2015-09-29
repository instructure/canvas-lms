define([
  'react',
  'react-router',
  'react-modal',
  'compiled/react_files/components/FilesApp',
  'compiled/react_files/modules/filesEnv',
  'i18n!react_files',
  'jsx/files/Breadcrumbs',
  'jsx/files/FolderTree',
  'jsx/files/FilesUsage',
  'compiled/react_files/components/Toolbar'
], function (React, ReactRouter, ReactModal, FilesApp, filesEnv, I18n, Breadcrumbs, FolderTree, FilesUsage, Toolbar) {

  var RouteHandler = ReactRouter.RouteHandler;

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
        {ENV.use_new_styles && contextType === 'courses' && (
          <div className='ic-app-nav-toggle-and-crumbs ic-app-nav-toggle-and-crumbs--files'>
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
              />
            </div>
          </div>
        )}

        {(!ENV.use_new_styles || contextType !== 'courses') && (
          <Breadcrumbs
            rootTillCurrentFolder={this.state.rootTillCurrentFolder}
            showingSearchResults={this.state.showingSearchResults}
          />
        )}
        <Toolbar
          currentFolder={this.state.currentFolder}
          query={this.getQuery()}
          selectedItems={this.state.selectedItems}
          clearSelectedItems={this.clearSelectedItems}
          contextType={contextType}
          contextId={contextId}
          userCanManageFilesForContext={userCanManageFilesForContext}
          usageRightsRequiredForContext={usageRightsRequiredForContext}
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
            <RouteHandler
              key={this.state.key}
              pathname={this.state.pathname}
              query={this.getQuery()}
              onResolvePath={this.onResolvePath}
              currentFolder={this.state.currentFolder}
              contextType={contextType}
              contextId={contextId}
              selectedItems={this.state.selectedItems}
              toggleItemSelected={this.toggleItemSelected}
              toggleAllSelected={this.toggleAllSelected}
              areAllItemsSelected={this.areAllItemsSelected}
              userCanManageFilesForContext={userCanManageFilesForContext}
              usageRightsRequiredForContext={usageRightsRequiredForContext}
              externalToolsForContext={externalToolsForContext}
              previewItem={this.previewItem}
              modalOptions={{
                openModal: this.openModal,
                closeModal: this.closeModal
              }}
              dndOptions={{
                onItemDragStart: this.onItemDragStart,
                onItemDragEnterOrOver: this.onItemDragEnterOrOver,
                onItemDragLeaveOrEnd: this.onItemDragLeaveOrEnd,
                onItemDrop: this.onItemDrop
              }}
              clearSelectedItems={this.clearSelectedItems}
            />
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
            closeTimeoutMS='10'
            className='ReactModal__Content--canvas'
            overlayClassName='ReactModal__Overlay--canvas'
          >
            {this.state.modalContents}
          </ReactModal>
        )}
      </div>
    );
  };

  return React.createClass(FilesApp);
});
