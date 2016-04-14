define([
  'react',
  'i18n!course_images',
  'classnames'
], (React, I18n, classnames) => {

  class UploadArea extends React.Component {
    render () {
      return (
        <div className="UploadArea">
          <div className="UploadArea__Content">
            <div className="UploadArea__Icon">
              <i className="icon-upload" />
            </div>
            <div className="UploadArea__Instructions">
              <strong>{I18n.t('Drag and drop your image here or browse your computer.')}</strong>
              <div className="UploadArea__FileTypes">
                {I18n.t('jpg, png, or gif files')}
              </div>
            </div>
          </div>
        </div>
      );
    }
  }

  return UploadArea;

});