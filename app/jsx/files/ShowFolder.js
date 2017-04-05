import React from 'react'
import _ from 'underscore'
import I18n from 'i18n!react_files'
import ShowFolder from 'compiled/react_files/components/ShowFolder'
import FilePreview from 'jsx/files/FilePreview'
import FolderChild from 'jsx/files/FolderChild'
import UploadDropZone from 'jsx/files/UploadDropZone'
import ColumnHeaders from 'jsx/files/ColumnHeaders'
import CurrentUploads from 'jsx/files/CurrentUploads'
import LoadingIndicator from 'jsx/files/LoadingIndicator'
import page from 'page'
import FocusStore from 'compiled/react_files/modules/FocusStore'

  ShowFolder.closeFilePreview = function (url) {
    page(url)
    FocusStore.setFocusToItem();
  }

  ShowFolder.renderFilePreview = function () {
    /* Prepare and render the FilePreview if needed.
       As long as ?preview is present in the url.
    */
    if (this.props.query.preview != null) {
      return (
        <FilePreview
          isOpen={true}
          usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
          currentFolder={this.props.currentFolder}
          params={this.props.params}
          query={this.props.query}
          pathname={this.props.pathname}
          splat={this.props.splat}
          closePreview={this.closeFilePreview}
        />
      );
    }
  }

  ShowFolder.renderFolderChildOrEmptyContainer = function () {
    if(this.props.currentFolder.isEmpty()) {
      return (
        <div ref='folderEmpty' className='muted'>
          {I18n.t('this_folder_is_empty', 'This folder is empty')}
        </div>
      );
    }
    else {
      return (
        this.props.currentFolder.children(this.props.query).map((child) => {
          return(
            <FolderChild
              key={child.cid}
              model={child}
              isSelected={(_.indexOf(this.props.selectedItems, child)) >= 0}
              toggleSelected={ this.props.toggleItemSelected.bind(null, child) }
              userCanManageFilesForContext={this.props.userCanManageFilesForContext}
              userCanRestrictFilesForContext={this.props.userCanRestrictFilesForContext}
              usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
              externalToolsForContext={this.props.externalToolsForContext}
              previewItem={this.props.previewItem.bind(null, child)}
              dndOptions={this.props.dndOptions}
              modalOptions={this.props.modalOptions}
              clearSelectedItems={this.props.clearSelectedItems}
              onMove={this.props.onMove}
            />
          );
        })
      );
    }
  }

  ShowFolder.render = function () {
    var currentState = this.state || {};
    if (currentState.errorMessages) {
      return (
        <div>
          {
            currentState.errorMessages.map(function(error){
              <div className='muted'>
                {error.message}
              </div>
            })
          }
        </div>
      );
    }

    if (!this.props.currentFolder) {
      return(<div ref='emptyDiv'></div>);
    }

    var folderOrRootFolder;
    if (this.props.params.splat){
      folderOrRootFolder = 'folder';
    }else{
      folderOrRootFolder = 'rootFolder';
    }

    var foldersNextPageOrFilesNextPage = this.props.currentFolder.folders.fetchingNextPage || this.props.currentFolder.files.fetchingNextPage;

    return (
      <div role='grid' style={{flex: "1 1 auto"}} >
        <div
          ref='accessibilityMessage'
          className='ShowFolder__accessbilityMessage col-xs'
          tabIndex={0}
        >
          {I18n.t("Warning: For improved accessibility in moving files, please use the Move To Dialog option found in the menu.")}
        </div>
        <UploadDropZone currentFolder={this.props.currentFolder} />
        <CurrentUploads />
        <ColumnHeaders
          ref='columnHeaders'
          query={this.props.query}
          pathname={this.props.pathname}
          toggleAllSelected={this.props.toggleAllSelected}
          areAllItemsSelected={this.props.areAllItemsSelected}
          usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
        />
        { this.renderFolderChildOrEmptyContainer() }
        <LoadingIndicator isLoading={foldersNextPageOrFilesNextPage} />
        {this.renderFilePreview() }
      </div>
    );
  }

export default React.createClass(ShowFolder)
