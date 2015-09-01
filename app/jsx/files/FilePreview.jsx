/** @jsx React.DOM */

define([
  'react',
  'i18n!react_files',
  'classnames',
  'react-router',
  'react-modal',
  'compiled/react_files/components/FilePreview',
  'jsx/files/FilePreviewInfoPanel',
  'compiled/react_files/utils/collectionHandler',
  'compiled/fn/preventDefault',
  'compiled/models/Folder'
], function (React, I18n, classnames, ReactRouter, ReactModal, FilePreview, FilePreviewInfoPanel, CollectionHandler, preventDefault, Folder) {

  var Link = ReactRouter.Link;

  FilePreview.renderArrowLink = function (direction) {
    var nextItem = (direction === 'left') ?
                   CollectionHandler.getPreviousInRelationTo(this.state.otherItems, this.state.displayedItem) :
                   CollectionHandler.getNextInRelationTo(this.state.otherItems, this.state.displayedItem);

    return (
      <div className='col-xs-1 ef-file-arrow_container'>
        <Link
          to={this.getRouteIdentifier()}
          query={this.getNavigationParams((nextItem) ? {id: nextItem.id} : null)}
          params={this.getParams()}
          className='ef-file-preview-container-arrow-link'
        >
          <div className='ef-file-preview-arrow-link'>
            <i className={`icon-arrow-open-${direction}`} />
          </div>
        </Link>
      </div>
    );
  };

  FilePreview.renderPreview = function () {
    if (this.state.displayedItem && this.state.displayedItem.get('preview_url')) {
      var iFrameClasses = classnames({
        'ef-file-preview-frame': true,
        'ef-file-preview-frame-html': this.state.displayedItem.get('content-type') === 'text/html'
      });

      return (
        <iframe
          allowFullScreen={true}
          title={I18n.t('File Preview')}
          src={this.state.displayedItem.get('preview_url')}
          className={iFrameClasses}
        />
      );
    } else if (this.state.displayedItem instanceof Folder) {
      return (
        <div className='ef-file-not-found ef-file-preview-frame'>
          <i className='media-object ef-not-found-icon FilesystemObjectThumbnail mimeClass-folder' />
          {this.state.displayedItem.attributes.name}
        </div>
      );
    } else {
      return (
        <div className='ef-file-not-found ef-file-preview-frame'>
          <i className='media-object ef-not-found-icon FilesystemObjectThumbnail mimeClass-file' />
          {I18n.t("File not found")}
        </div>
      );
    }
  }

  FilePreview.render = function () {

    var showInfoPanelClasses = classnames({
      'ef-file-preview-header-info': true,
      'ef-file-preview-button': true,
      'ef-file-preview-button--active': this.state.showInfoPanel
    });

    return (
      <ReactModal
        isOpen={true}
        onRequestClose={this.closeModal}
        className='ReactModal__Content--ef-file-preview'
        overlayClassName='ReactModal__Overlay--ef-file-preview'
        closeTimeoutMS={10}
      >
        <div className='ef-file-preview-overlay'>
          <div className='ef-file-preview-header'>
            <h1 className='ef-file-preview-header-filename'>
              {(this.state.initialItem) ? this.state.initialItem.displayName() : '' }
            </h1>
            <div className='ef-file-preview-header-buttons'>
              {this.state.displayedItem && !this.state.displayedItem.get('locked_for_user') && (
                <a
                  href={this.state.displayedItem.get('url')}
                  download={true}
                  className='ef-file-preview-header-download ef-file-preview-button'
                >
                  <i className='icon-download' />
                  {' ' + I18n.t('Download')}
                </a>
              )}
              <button
                type='button'
                className={showInfoPanelClasses}
                onClick={this.toggle('showInfoPanel')}
              >
                {/* Wrap content in a div because firefox doesn't support display: flex on buttons */}
                <div>
                  <i className='icon-info' />
                  {' ' + I18n.t('Info')}
                </div>
              </button>
              <a
                href='#'
                onClick={preventDefault(this.closeModal)}
                className='ef-file-preview-header-close ef-file-preview-button'
              >
                <i className='icon-end' />
                {' ' + I18n.t('Close')}
              </a>
            </div>
          </div>
          <div className='ef-file-preview-stretch'>
            {(this.state.otherItems && this.state.otherItems.length) && this.renderArrowLink('left')}
            {this.renderPreview()}
            {(this.state.otherItems && this.state.otherItems.length) && this.renderArrowLink('right')}
            {this.state.showInfoPanel && (
              <FilePreviewInfoPanel
                displayedItem={this.state.displayedItem}
                getStatusMessage={this.getStatusMessage}
                usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
              />
            )}
          </div>
        </div>
      </ReactModal>
    );
  };
  return React.createClass(FilePreview);

});
