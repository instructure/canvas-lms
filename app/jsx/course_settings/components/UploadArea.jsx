define([
  'react',
  'i18n!course_images',
  'classnames',
  'str/htmlEscape'
], (React, I18n, classnames, htmlEscape) => {

  class UploadArea extends React.Component {
    constructor (props) {
      super(props);

      this.handleFileChange = this.handleFileChange.bind(this);
      this.uploadFile = this.uploadFile.bind(this);
    }

    handleFileChange (e) {
      this.props.handleFileUpload(e, this.props.courseId);
      e.preventDefault();
      e.stopPropagation();
    }

    uploadFile () {
      this.refs.courseImagefileUpload.click();  
    }

    render () {

      return (
        <div className="UploadArea">
          <div className="UploadArea__Content">
            <div className="UploadArea__Icon">
              <i className="icon-upload" />
            </div>
            <div className="UploadArea__Instructions">
              <strong> 
                {I18n.t('Drag and drop your image here or ')}
                <a tabIndex="0" role="button" href="#" onClick={this.uploadFile}>
                  <span className="screenreader-only">{I18n.t('Browse your computer for a course image')}</span>
                  <span aria-hidden="true">{I18n.t('browse your computer')}</span>
                </a>
              </strong>
              <input
                type="file"
                ref="courseImagefileUpload"
                name="fileUpload"
                className="FileUpload__Input"
                accept=".jpg, .jpeg, .gif, .png, image/png, image/jpeg, image/gif"
                aria-hidden="true"
                onChange={this.handleFileChange}
              />
            </div>
            <div className="UploadArea__FileTypes">
              {I18n.t('jpg, png, or gif files')}
            </div>
          </div>
        </div>
      );
    }
  }

  return UploadArea;

});