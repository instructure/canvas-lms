define([
  'jquery',
  'i18n!react_files',
  'react',
  'react-dom',
  'page',
  'compiled/react_files/components/Toolbar',
  'compiled/react_files/modules/FocusStore',
  'jsx/files/utils/openMoveDialog',
  'compiled/react_files/utils/deleteStuff',
  'jsx/files/UploadButton',
  'classnames',
  'compiled/fn/preventDefault',
  'compiled/models/Folder'
], function ($, I18n, React, ReactDOM, page, Toolbar, FocusStore, openMoveDialog, deleteStuff, UploadButton, classnames, preventDefault, Folder) {

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
          dataTooltip= ''
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
          dataTooltip= ''
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
          dataTooltip= ''
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
            dataTooltip= ''
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
            dataTooltip= ''
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
          dataTooltip= ''
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
      return item.get('restricted_by_master_course');
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
              dataTooltip= ''
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
  return React.createClass(Toolbar);
});
