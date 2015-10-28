define([
  'i18n!react_files',
  'react',
  'react-router',
  'compiled/react_files/components/FolderChild',
  'classnames',
  'jsx/files/ItemCog',
  'jsx/shared/PublishCloud',
  'jsx/files/FilesystemObjectThumbnail',
  'jsx/files/UsageRightsIndicator',
  'compiled/models/Folder',
  'compiled/fn/preventDefault',
  'jsx/shared/FriendlyDatetime',
  'compiled/util/friendlyBytes'
], function(I18n, React, ReactRouter, FolderChild, classnames, ItemCog, PublishCloud, FilesystemObjectThumbnail, UsageRightsIndicator, Folder, preventDefault, FriendlyDatetime, friendlyBytes) {
  var Link = ReactRouter.Link
  FolderChild.renderItemCog = function () {
    if (!this.props.model.isNew() || this.props.model.get('locked_for_user')) {
      return (
        <ItemCog
          model= {this.props.model}
          startEditingName= {this.startEditingName}
          userCanManageFilesForContext= {this.props.userCanManageFilesForContext}
          usageRightsRequiredForContext= {this.props.usageRightsRequiredForContext}
          externalToolsForContext= {this.props.externalToolsForContext}
          modalOptions= {this.props.modalOptions}
          clearSelectedItems= {this.props.clearSelectedItems}
          onMove={this.props.onMove}
        />
      );
    }
  }
  FolderChild.renderPublishCloud = function () {
    if (!this.props.model.isNew()){
      return (
        <PublishCloud
          model= {this.props.model}
          ref= 'publishButton'
          userCanManageFilesForContext= {this.props.userCanManageFilesForContext}
          usageRightsRequiredForContext= {this.props.usageRightsRequiredForContext}
        />
      );
    }
  }

  FolderChild.renderEditingState = function () {
    if(this.state.editing) {
      return (
        <form className= 'ef-edit-name-form' onSubmit= {preventDefault(this.saveNameEdit)}>
          <input
            type='text'
            ref='newName'
            className= 'input-block-level'
            placeholder= {I18n.t('name', 'Name')}
            ariaLabel= {I18n.t('folder_name', 'Folder Name')}
            defaultValue= {this.props.model.displayName()}
            maxLength='255'
            onKeyUp= {function (event){ if (event.keyCode === 27) {this.cancelEditingName()} }.bind(this)}
          />
          <button
            type= 'button'
            className= 'btn btn-link ef-edit-name-cancel'
            ariaLabel= {I18n.t('cancel', 'Cancel')}
            onClick= {this.cancelEditingName}
          >
            <i className= 'icon-x' />
          </button>
        </form>
      );
    }else if(this.props.model instanceof Folder) {
      return (
        <Link
          ref= 'nameLink'
          to= 'folder'
          className= 'media'
          onClick= {this.checkForAccess}
          params= {{splat: this.props.model.urlPath()}}
        >
          <span className= 'pull-left'>
            <FilesystemObjectThumbnail model= {this.props.model} />
          </span>
          <span className= 'media-body'>
            {this.props.model.displayName()}
          </span>
        </Link>
      );
    } else{
      return (
        <a
          href= {this.props.model.get('url')}
          onClick= {preventDefault(this.handleFileLinkClick)}
          className= 'media'
          ref= 'nameLink'
        >
          <span className= 'pull-left'>
            <FilesystemObjectThumbnail model= {this.props.model} />
          </span>
          <span className= 'media-body'>
            {this.props.model.displayName()}
          </span>
        </a>
      );
    }
  }

  FolderChild.renderUsageRightsIndicator = function () {
    if (this.props.usageRightsRequiredForContext) {
      return (
        <div className= 'ef-usage-rights-col' role= 'gridcell'>
          <UsageRightsIndicator
            model= {this.props.model}
            userCanManageFilesForContext= {this.props.userCanManageFilesForContext}
            usageRightsRequiredForContext= {this.props.usageRightsRequiredForContext}
            modalOptions= {this.props.modalOptions}
          />
        </div>
      );
    }
  }

  FolderChild.render = function () {
    var user = this.props.model.get('user') || {};
    var selectCheckboxLabel = I18n.t('Select %{itemName}', {itemName: this.props.model.displayName()})
    var keyboardCheckboxClass = classnames({
      'screenreader-only': this.state.hideKeyboardCheck,
      'multiselectable-toggler': true
    })
    var keyboardLabelClass = classnames({
      'screenreader-only': !this.state.hideKeyboardCheck
    })

    return (
      <div {...this.getAttributesForRootNode()}>
        <label className= {keyboardCheckboxClass} role= 'gridcell'>
          <input
            type= 'checkbox'
            ariaLabel= {selectCheckboxLabel}
            onFocus= {function(){ this.setState({hideKeyboardCheck: false})}.bind(this)}
            onBlur = {function () {this.setState({hideKeyboardCheck: true})}.bind(this)}
            className = {keyboardCheckboxClass}
            checked= {this.props.isSelected}
            onChange= {function () {}}
          />
          <span className= {keyboardLabelClass}>
            {selectCheckboxLabel}
          </span>
        </label>

        <div className='ef-name-col ellipsis' role= 'rowheader'>
          { this.renderEditingState() }
        </div>

        <div className='ef-date-created-col' role= 'gridcell'>
          <FriendlyDatetime dateTime={this.props.model.get('created_at')} />
        </div>

        <div className='ef-date-modified-col' role= 'gridcell'>
          {!(this.props.model instanceof Folder) && (
            <FriendlyDatetime dateTime={this.props.model.get('modified_at')} />
          )}
        </div>

        <div className='ef-modified-by-col ellipsis' role= 'gridcell'>
          <a href= {user.html_url} className= 'ef-plain-link'>
            {user.display_name}
          </a>
        </div>

        <div className='ef-size-col' role= 'gridcell'>
          {friendlyBytes(this.props.model.get('size'))}
        </div>

        { this.renderUsageRightsIndicator() }

        <div className= 'ef-links-col' role= 'gridcell'>
          { this.renderPublishCloud() }
          { this.renderItemCog() }
        </div>
      </div>
    );
  }

  return React.createClass(FolderChild);
});
