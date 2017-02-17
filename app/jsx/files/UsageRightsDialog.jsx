define([
  'react',
  'compiled/react_files/components/UsageRightsDialog',
  'i18n!usage_rights_modal',
  'jsx/files/UsageRightsSelectBox',
  'jsx/files/RestrictedRadioButtons',
  'jsx/files/DialogPreview',
  'compiled/models/Folder',
  'str/htmlEscape'
], function (React, UsageRightsDialog, I18n, UsageRightsSelectBox, RestrictedRadioButtons, DialogPreview, Folder, htmlEscape) {

  var MAX_THUMBNAILS_TO_SHOW = 5;
  var MAX_FOLDERS_TO_SHOW = 2;

  UsageRightsDialog.renderFileName = function () {
    var textToShow = (this.props.itemsToManage.length > 1) ?
                     I18n.t('%{items} items selected', {items: this.props.itemsToManage.length}) :
                     this.props.itemsToManage[0].displayName();

    return (
      <span ref='fileName' className='UsageRightsDialog__fileName'>{textToShow}</span>
    );
  };

  UsageRightsDialog.renderFolderList = function (folders) {
    if (folders.length) {
      var foldersToShow = folders.slice(0, MAX_FOLDERS_TO_SHOW);
      return (
        <div>
          <span>{I18n.t("Usage rights will be set for all of the files contained in:")}</span>
          <ul ref='folderBulletList' className='UsageRightsDialog__folderBulletList'>
          {foldersToShow.map((item) => {
            return (<li>{item.displayName()}</li>);
          })}
          </ul>
        </div>
      );
    } else {
      return null;
    }
  };

  UsageRightsDialog.renderFolderTooltip = function (folders) {
    var toolTipFolders = folders.slice(MAX_FOLDERS_TO_SHOW);

    if (toolTipFolders.length) {
      var displayNames = toolTipFolders.map((item) => {return htmlEscape(item.displayName()).toString();});
      // Doing it this way so commas, don't show up when rendering the list out in the tooltip.
      var renderedNames = displayNames.join('<br />');

      return (
        <span
          className='UsageRightsDialog__andMore'
          tabIndex='0'
          ref='folderTooltip'
          data-html-tooltip-title={renderedNames}
          data-tooltip='right'
          data-tooltip-class='UsageRightsDialog__tooltip'
        >
          {I18n.t('and %{count} more…', {count: toolTipFolders.length})}
          <span className='screenreader-only'>
            <ul>
              {displayNames.map((item) => {
                return (<li ref='displayNameTooltip-screenreader'> {item}</li>);
              })}
            </ul>
          </span>
        </span>
      );

    } else {
      return null;
    }
  }

  UsageRightsDialog.renderFolderMessage = function () {
    var folders = this.props.itemsToManage.filter((item) => {
      return item instanceof Folder;
    });

    return (
      <div>
        {this.renderFolderList(folders)}
        {this.renderFolderTooltip(folders)}
        <hr />
      </div>
    );
  };

  UsageRightsDialog.renderDifferentRightsMessage = function () {
    if ((this.copyright == null || this.use_justification === 'choose') &&
        this.props.itemsToManage.length > 1) {
      return (
        <span ref='differentRightsMessage' className='UsageRightsDialog__differentRightsMessage alert'>
          <i className='icon-warning UsageRightsDialog__warning' />
          {I18n.t('Items selected have different usage rights.')}
        </span>
      );
    }
  };

  UsageRightsDialog.renderAccessManagement = function () {
    if (this.props.userCanRestrictFilesForContext) {
      return (
        <div>
          <hr />
          <div className='form-horizontal'>
            <p className="manage-access">{I18n.t("You can also manage access at this time:")}</p>
            <RestrictedRadioButtons
              ref='restrictedSelection'
              models={this.props.itemsToManage}
            >
            </RestrictedRadioButtons>
          </div>
        </div>
      );
    }
  };

  UsageRightsDialog.render = function () {
    return (
      <div className='ReactModal__Layout'>
        <div className='ReactModal__Header'>
          <div className='ReactModal__Header-Title'>
            <h4>
              {I18n.t('Manage Usage Rights')}
            </h4>
          </div>
          <div className='ReactModal__Header-Actions'>
            <button
              ref='cancelXButton'
              className='Button Button--icon-action'
              type='button'
              onClick={this.props.closeModal}
            >
              <i className='icon-x'>
                <span className='screenreader-only'>
                  {I18n.t('Close')}
                </span>
              </i>
            </button>
          </div>
        </div>
        <div className='ReactModal__Body'>
          <div ref='form'>
            <div>
              <div className='UsageRightsDialog__paddingFix grid-row'>
                <div className='UsageRightsDialog__previewColumn col-xs-3'>
                  <DialogPreview itemsToShow={this.props.itemsToManage} >
                  </DialogPreview>
                </div>
                <div className='UsageRightsDialog__contentColumn off-xs-1 col-xs-8'>
                  {this.renderDifferentRightsMessage()}
                  {this.renderFileName()}
                  {this.renderFolderMessage()}
                  <UsageRightsSelectBox
                    ref='usageSelection'
                    use_justification={this.use_justification}
                    copyright={this.copyright || ''}
                    cc_value={this.cc_value}
                  >
                  </UsageRightsSelectBox>
                  {this.renderAccessManagement()}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className='ReactModal__Footer'>
          <div className='ReactModal__Footer-Actions'>
            <button
              ref='cancelButton'
              type='button'
              className='btn'
              onClick={this.props.closeModal}
            >
              {I18n.t('Cancel')}
            </button>
            <button
              ref='saveButton'
              type='button'
              className='btn btn-primary'
              onClick={this.submit}
            >
              {I18n.t('Save')}
            </button>
          </div>
        </div>
      </div>
    );
  };

  return React.createClass(UsageRightsDialog);

});
