/** @jsx React.DOM */

define([
  'react',
  'i18n!react_files',
  'classnames',
  'compiled/react_files/components/UploadProgress',
  'jsx/shared/ProgressBar',
  'compiled/util/mimeClass'
  ], function(React, I18n, classnames, UploadProgress, ProgressBar, mimeClass) {

    UploadProgress.renderProgressBar = function () {
      if (this.props.uploader.error) {
        var errorMessage = (this.props.uploader.error.message) ?
                          I18n.t('Error: %{message}', {message: this.props.uploader.error.message}) :
                          I18n.t('Error uploading file.')

        return (
          <span>
            {errorMessage}
            <button type='button' className='btn-link' onClick={ () => this.props.uploader.upload()}>
              {I18n.t('Retry')}
            </button>
          </span>
        );
      } else {
        return <ProgressBar progress={this.props.uploader.roundProgress()} />
      }
    };

    UploadProgress.render = function () {

      var rowClassNames = classnames({
        'ef-item-row': true,
        'text-error': this.props.uploader.error
      });

      return (
        <div className={rowClassNames}>
          <div className='col-xs-6'>
            <div className='media ellipsis'>
              <span className='pull-left'>
                <i className={`media-object mimeClass-${mimeClass(this.props.uploader.file.type)}`} />
              </span>
              <span className='media-body' ref='fileName'>
                {this.props.uploader.getFileName()}
              </span>
            </div>
          </div>
          <div className='col-xs-5'>
            {this.renderProgressBar()}
          </div>
          <button
            type='button'
            onClick={this.props.uploader.cancel}
            aria-label={I18n.t('Cancel')}
            className='btn-link upload-progress-view__button'
          >
            x
          </button>
        </div>
      );
    };

    return React.createClass(UploadProgress);

});