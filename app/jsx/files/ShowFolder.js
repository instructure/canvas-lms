/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import _ from 'underscore'
import classnames from 'classnames'
import I18n from 'i18n!react_files'
import ShowFolder from 'compiled/react_files/components/ShowFolder'
import FilePreview from '../files/FilePreview'
import FolderChild from '../files/FolderChild'
import UploadDropZone from '../files/UploadDropZone'
import ColumnHeaders from '../files/ColumnHeaders'
import CurrentUploads from '../files/CurrentUploads'
import LoadingIndicator from '../files/LoadingIndicator'
import page from 'page'
import FocusStore from 'compiled/react_files/modules/FocusStore'

  ShowFolder.getInitialState = function () {
    return {
      hideToggleAll: true,
    }
  }

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

    const selectAllLabelClass = classnames({
      'screenreader-only': this.state.hideToggleAll
    });

    // We have to put the "select all" checkbox out here because VO won't read the table properly
    // if it's in the table header, and won't read it at all if it's outside the table but inside
    // the <div role="grid">.
    return (
      <div>
        <input
          id='selectAllCheckbox'
          className={selectAllLabelClass}
          type='checkbox'
          onFocus={(event) => this.setState({hideToggleAll: false})}
          onBlur={(event) => this.setState({hideToggleAll: true})}
          checked={this.props.areAllItemsSelected()}
          onChange={(event) => this.props.toggleAllSelected(event.target.checked)}
        />
        <label htmlFor='selectAllCheckbox' className={selectAllLabelClass}>
          {I18n.t('select_all', 'Select All')}
        </label>
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
            areAllItemsSelected={this.props.areAllItemsSelected}
            usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
          />
          { this.renderFolderChildOrEmptyContainer() }
          <LoadingIndicator isLoading={foldersNextPageOrFilesNextPage} />
          {this.renderFilePreview() }
        </div>
      </div>
    );
  }

export default React.createClass(ShowFolder)
