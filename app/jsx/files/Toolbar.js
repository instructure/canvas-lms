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

import $ from 'jquery'
import I18n from 'i18n!react_files'
import React from 'react'
import ReactDOM from 'react-dom'
import page from 'page'
import Toolbar from 'compiled/react_files/components/Toolbar'
import FocusStore from 'compiled/react_files/modules/FocusStore'
import openMoveDialog from '../files/utils/openMoveDialog'
import deleteStuff from 'compiled/react_files/utils/deleteStuff'
import UploadButton from '../files/UploadButton'
import classnames from 'classnames'
import preventDefault from 'compiled/fn/preventDefault'
import Folder from 'compiled/models/Folder'

  Toolbar.openPreview = function () {
    FocusStore.setItemToFocus(ReactDOM.findDOMNode(this.refs.previewLink));
    const queryString  = $.param(this.props.getPreviewQuery());
    page(`${this.props.getPreviewRoute()}?${queryString}`);
  };

  Toolbar.onSubmitSearch = function (event) {
    event.preventDefault();
    const searchTerm = ReactDOM.findDOMNode(this.refs.searchTerm).value;
    page(`/search?search_term=${searchTerm}`);
  };

  Toolbar.renderUploadAddFolderButtons = function (canManage) {
    var phoneHiddenSet = classnames({
      'hidden-phone' : this.showingButtons
    });
    if (canManage) {
      return (
        <div className='ef-actions'>
          <button
            type= 'button'
            onClick= {this.addFolder}
            className='btn btn-add-folder'
            aria-label= {I18n.t('Add Folder')}
          >
            <i className='icon-plus' />&nbsp;
            <span className= {phoneHiddenSet} >
              {I18n.t('Folder')}
            </span>
          </button>

          <UploadButton
            currentFolder= {this.props.currentFolder}
            showingButtons= {this.showingButtons}
            contextId= {this.props.contextId}
            contextType= {this.props.contextType}
          />
        </div>
      );
    }
  }
  Toolbar.renderDeleteButton = function (canManage) {
    if (canManage) {
      return (
        <button
          type= 'button'
          disabled= {!this.showingButtons}
          className= 'ui-button btn-delete'
          onClick= { function () {
            this.props.clearSelectedItems()
            deleteStuff(this.props.selectedItems)
          }.bind(this)
          }
          title= {I18n.t('Delete')}
          aria-label= {I18n.t('Delete')}
          data-tooltip=""
        >
          <i className='icon-trash' />
        </button>
      );
    }
  }
  Toolbar.renderManageUsageRightsButton = function () {
    if (this.props.userCanManageFilesForContext && this.props.usageRightsRequiredForContext) {
      return (
        <button
          ref= 'usageRightsBtn'
          type= 'button'
          disabled= {!this.showingButtons}
          className= 'Toolbar__ManageUsageRights ui-button btn-rights'
          onClick= {this.openUsageRightsDialog}
          title= {I18n.t('Manage Usage Rights')}
          aria-label= {I18n.t('Manage Usage Rights')}
          data-tooltip=""
        >
          <i className= 'icon-files-copyright' />
        </button>
      );
    }
  }
  Toolbar.renderCopyCourseButton = function (canManage) {
    if (canManage) {
      return (
        <button
          type='button'
          disabled= {!this.showingButtons}
          className= 'ui-button btn-move'
          onClick= {function(event) {
            openMoveDialog(this.props.selectedItems, {
              contextType: this.props.contextType,
              contextId: this.props.contextId,
              returnFocusTo: event.target,
              clearSelectedItems: this.props.clearSelectedItems,
              onMove: this.props.onMove
            })
          }.bind(this)}
          title= {I18n.t('Move')}
          aria-label= {I18n.t('Move')}
          data-tooltip=""
        >
          <i className='icon-updown' />
        </button>
      );
    }
  }

  Toolbar.renderDownloadButton = function () {
    if (this.getItemsToDownload().length) {
      if ((this.props.selectedItems.length === 1) && this.props.selectedItems[0].get('url')) {
        return (
          <a
            className= 'ui-button btn-download'
            href= {this.props.selectedItems[0].get('url')}
            download= {true}
            title= {this.downloadTitle}
            aria-label= {this.downloadTitle}
            data-tooltip=""
          >
            <i className='icon-download' />
          </a>
        );
      } else {
        return (
          <button
            type= 'button'
            disabled= {!this.showingButtons}
            className='ui-button btn-download'
            onClick= {this.downloadSelectedAsZip}
            title= {this.downloadTitle}
            aria-label= {this.downloadTitle}
            data-tooltip=""
          >
            <i className='icon-download'/>
          </button>
        );
      }
    }
  }

  Toolbar.componentDidUpdate = function (prevProps) {
    if (prevProps.selectedItems.length !== this.props.selectedItems.length){
      $.screenReaderFlashMessageExclusive(I18n.t({one: '%{count} item selected', other: '%{count} items selected'}, {count: this.props.selectedItems.length}))
    }
  }

  Toolbar.renderRestrictedAccessButtons = function (canManage) {
    if (canManage){
      return (
        <button
          type= 'button'
          disabled= {!this.showingButtons}
          className= 'ui-button btn-restrict'
          onClick= {this.openRestrictedDialog}
          title= {I18n.t('Manage Access')}
          aria-label= {I18n.t('Manage Access')}
          data-tooltip=""
        >
          <i className= 'icon-cloud-lock' />
        </button>
       );
    }
  }

  Toolbar.render = function () {
    var selectedItemIsFolder = this.props.selectedItems.every(function(item) {
      return item instanceof Folder;
    });
    var submissionsFolderSelected = this.props.currentFolder && this.props.currentFolder.get('for_submissions');
    submissionsFolderSelected = submissionsFolderSelected || this.props.selectedItems.some(function(item) {
      return item.get('for_submissions');
    });
    var restrictedByMasterCourse = this.props.selectedItems.some(function(item) {
      return item.get('restricted_by_master_course') && item.get('is_master_course_child_content');
    });
    var canManage = this.props.userCanManageFilesForContext && !submissionsFolderSelected && !restrictedByMasterCourse;

    this.showingButtons = this.props.selectedItems.length

    if (this.showingButtons === 1) {
      this.downloadTitle = I18n.t('Download');
    }

    var formClassName = classnames({
      "ic-Input-group" : true,
      "ef-search-form" : true,
      "ef-search-form--showing-buttons" : this.showingButtons
    });


    var buttonSetClasses = classnames({
      "ui-buttonset" : true,
      "screenreader-only" : !this.showingButtons
    });

    var viewBtnClasses = classnames({
      'ui-button': true,
      'btn-view': true,
      'Toolbar__ViewBtn--onlyfolders': selectedItemIsFolder
    });

    return (
      <header
        className='ef-header'
        role='region'
        aria-label= {I18n.t('Files Toolbar')}
      >
        <form
          className= { formClassName }
          onSubmit={this.onSubmitSearch}
        >
          <input
            placeholder= {I18n.t('Search for files')}
            aria-label= {I18n.t('Search for files')}
            type= 'search'
            ref='searchTerm'
            role='textbox'
            className='ic-Input'
            defaultValue= {this.props.query.search_term}
          />
          <button
            className='Button'
            type='submit'
          >
            <i className='icon-search' />
            <span className='screenreader-only'>
              {I18n.t('Search for files') }
            </span>
          </button>
        </form>

        <div className='ef-header__secondary'>
          <div className={buttonSetClasses}>
            <a
              ref= 'previewLink'
              href= '#'
              onClick= {!selectedItemIsFolder && preventDefault(this.openPreview)}
              className= {viewBtnClasses}
              title= {selectedItemIsFolder ? I18n.t('Viewing folders is not available') : I18n.t('View')}
              role= 'button'
              aria-label= {selectedItemIsFolder ? I18n.t('Viewing folders is not available') : I18n.t('View')}
              data-tooltip=""
              disabled= {!this.showingButtons || selectedItemIsFolder}
              tabIndex= {selectedItemIsFolder ? -1 : 0}
            >
              <i className= 'icon-eye' />
            </a>

            { this.renderRestrictedAccessButtons(canManage && this.props.userCanRestrictFilesForContext) }
            { this.renderDownloadButton() }
            { this.renderCopyCourseButton(canManage) }
            { this.renderManageUsageRightsButton(canManage) }
            { this.renderDeleteButton(canManage) }
          </div>
          <span className= 'ef-selected-count hidden-tablet hidden-phone'>
            {I18n.t({one: '%{count} item selected', other: '%{count} items selected'}, {count: this.props.selectedItems.length})}
          </span>
          { this.renderUploadAddFolderButtons(canManage) }
        </div>
      </header>
    );
  }

export default React.createClass(Toolbar)
