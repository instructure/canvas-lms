define([
  'i18n!react_files',
  'react',
  'compiled/react_files/components/Toolbar',
  'jsx/files/utils/openMoveDialog',
  'compiled/react_files/utils/deleteStuff',
  'jsx/files/UploadButton',
  'classnames',
  'compiled/fn/preventDefault',
  'compiled/models/Folder'
], function (I18n, React, Toolbar, openMoveDialog, deleteStuff, UploadButton, classnames, preventDefault, Folder) {

  Toolbar.renderUploadAddFolderButtons = function () {
    var phoneHiddenSet = classnames({
      'hidden-phone' : this.showingButtons
    });
    if (this.props.userCanManageFilesForContext) {
      return (
        <div className='ef-actions'>
          <button
            type= 'button'
            onClick= {this.addFolder}
            className='btn btn-add-folder'
            ariaLabel= {I18n.t('Add Folder')}
          >
            <i className='icon-plus' />
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
  Toolbar.renderDeleteButton = function () {
    if (this.props.userCanManageFilesForContext) {
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
          ariaLabel= {I18n.t('Delete')}
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
          ariaLabel= {I18n.t('Manage Usage Rights')}
          dataTooltip= ''
        >
          <i className= 'icon-files-copyright' />
        </button>
      );
    }
  }
  Toolbar.renderCopyCourseButton = function () {
    if (this.props.userCanManageFilesForContext) {
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
          ariaLabel= {I18n.t('Move')}
          dataTooltip= ''
        >
          <i className='icon-copy-course' />
        </button>
      );
    }
  }

  Toolbar.renderDownloadButton = function () {
    if (this.getItemsToDownload().length) {
      if ((this.props.selectedItems.length === 1) && this.props.selectedItems[0].get('url')) {
        return (
          <a
            tabIndex= {this.tabIndex}
            className= 'ui-button btn-download'
            href= {this.props.selectedItems[0].get('url')}
            download= {true}
            title= {this.downloadTitle}
            ariaLabel= {this.downloadTitle}
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
            ariaLabel= {this.downloadTitle}
            dataTooltip= ''
          >
            <i className='icon-download'/>
          </button>
        );
      }
    }
  }

  Toolbar.renderRestrictedAccessButtons = function () {
    if (this.props.userCanManageFilesForContext){
      return (
        <button
          type= 'button'
          disabled= {!this.showingButtons}
          className= 'ui-button btn-restrict'
          onClick= {this.openRestrictedDialog}
          title= {I18n.t('Manage Access')}
          ariaLabel= {I18n.t('Manage Access')}
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

    this.showingButtons = this.props.selectedItems.length
    if(!this.showingButtons || selectedItemIsFolder){
      this.tabIndex = -1;
    }

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
        ariaLabel= {I18n.t('Files Toolbar')}
      >
        <form
          className= { formClassName }
          onSubmit={this.onSubmitSearch}
        >
          <input
            placeholder= {I18n.t('Search for files')}
            ariaLabel= {I18n.t('Search for files')}
            type= 'search'
            ref='searchTerm'
            className='ic-Input'
            defaultValue= {this.getQuery().search_term}
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
              ariaLabel= {selectedItemIsFolder ? I18n.t('Viewing folders is not available') : I18n.t('View')}
              dataTooltip= ''
              ariaDisabled= {!this.showingButtons || selectedItemIsFolder}
              disabled= {!this.showingButtons || selectedItemIsFolder}
              tabIndex= {this.tabIndex}
            >
              <i className= 'icon-eye' />
            </a>

            { this.renderRestrictedAccessButtons() }
            { this.renderDownloadButton() }
            { this.renderCopyCourseButton() }
            { this.renderManageUsageRightsButton() }
            { this.renderDeleteButton() }
          </div>
          <span className= 'ef-selected-count hidden-tablet hidden-phone'>
            {I18n.t({one: '%{count} item selected', other: '%{count} items selected'}, {count: this.props.selectedItems.length})}
          </span>
          { this.renderUploadAddFolderButtons() }
        </div>
      </header>
    );
  }

  return React.createClass(Toolbar);
});

