import React from 'react'
import I18n from 'i18n!react_files'
import classnames from 'classnames'
import UploadProgress from 'compiled/react_files/components/UploadProgress'
import ProgressBar from 'jsx/shared/ProgressBar'
import mimeClass from 'compiled/util/mimeClass'

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

export default React.createClass(UploadProgress)
