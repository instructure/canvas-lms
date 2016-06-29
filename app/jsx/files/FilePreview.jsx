define([
  'react',
  'page',
  'jquery',
  'i18n!react_files',
  'classnames',
  'react-modal',
  'compiled/react_files/components/FilePreview',
  'jsx/files/FilePreviewInfoPanel',
  'compiled/react_files/utils/collectionHandler',
  'compiled/fn/preventDefault',
  'compiled/models/Folder'
], function (React, page, $, I18n, classnames, ReactModal, FilePreview, FilePreviewInfoPanel, CollectionHandler, preventDefault, Folder) {

  const modalOverrides = {
    overlay : {
      backgroundColor: 'rgba(0,0,0,0.75)'
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

  FilePreview.handleKeyboardNavigation = function (event) {
    if (!((event.keyCode === $.ui.keyCode.LEFT) || (event.keyCode === $.ui.keyCode.RIGHT))) {
      return null;
    }
    let nextItem = null;
    if (event.keyCode === $.ui.keyCode.LEFT) {
      nextItem = CollectionHandler.getPreviousInRelationTo(this.state.otherItems, this.state.displayedItem);
    }
    if (event.keyCode === $.ui.keyCode.RIGHT) {
      nextItem = CollectionHandler.getNextInRelationTo(this.state.otherItems, this.state.displayedItem);
    }

    page(`${this.getRouteIdentifier()}?${$.param(this.getNavigationParams({id: nextItem.id}))}`);

  };

  FilePreview.closeModal = function () {
    this.props.closePreview(`${this.getRouteIdentifier()}?${$.param(this.getNavigationParams({except: 'only_preview'}))}`);
  };

  FilePreview.getRouteIdentifier = function () {
    if (this.props.query && this.props.query.search_term) {
      return '/search';
    } else if (this.props.splat) {
      return `/folder/${this.props.splat}`;
    } else {
      return '';
    }
  };

  FilePreview.renderArrowLink = function (direction) {
    var nextItem = (direction === 'left') ?
                   CollectionHandler.getPreviousInRelationTo(this.state.otherItems, this.state.displayedItem) :
                   CollectionHandler.getNextInRelationTo(this.state.otherItems, this.state.displayedItem);

    var linkText = (direction === 'left') ? I18n.t('View previous file') : I18n.t('View next file')
    const baseUrl = page.base();
    return (
      <div className='col-xs-1 ef-file-arrow_container'>
        <a
          href={`${baseUrl}${this.getRouteIdentifier()}?${$.param(this.getNavigationParams((nextItem) ? {id: nextItem.id} : null))}`}
          className='ef-file-preview-container-arrow-link'
        >
          <div className='ef-file-preview-arrow-link'>
            <span className='screenreader-only'>{linkText}</span>
            <i aria-hidden='true' className={`icon-arrow-open-${direction}`} />
          </div>
        </a>
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
        ref='modal'
        isOpen={this.props.isOpen}
        onRequestClose={this.closeModal}
        className='ReactModal__Content--ef-file-preview'
        overlayClassName='ReactModal__Overlay--ef-file-preview'
        style={modalOverrides}
        closeTimeoutMS={10}
        appElement={document.getElementById('application')}
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
