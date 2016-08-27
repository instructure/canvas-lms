define([
  'react',
  'i18n!course_images',
  'underscore',
  './UploadArea',
  '../../shared/FlickrSearch',
  'instructure-ui'
], (React, I18n, _, UploadArea, FlickrSearch, InstUI) => {

  const Spinner = InstUI.Spinner;

  class CourseImagePicker extends React.Component {
    constructor (props) {
      super(props);

      this.state = {
        draggingFile: false
      };

      this.onDrop = this.onDrop.bind(this);
      this.onDragLeave = this.onDragLeave.bind(this);
      this.onDragEnter = this.onDragEnter.bind(this);
      this.shouldAcceptDrop = this.shouldAcceptDrop.bind(this);
    }

    onDrop (e) {
      this.setState({draggingFile: false});
      this.props.handleFileUpload(e, this.props.courseId);
      e.preventDefault();
      e.stopPropagation();
    }

    onDragLeave () {
      this.setState({draggingFile: false});
    }

    onDragEnter (e) {
      if (this.shouldAcceptDrop(e.dataTransfer)) {
        this.setState({draggingFile: true});
        e.preventDefault();
        e.stopPropagation();
      }
    }

    shouldAcceptDrop (dataTransfer) {
      if (dataTransfer) {
        return (_.indexOf(dataTransfer.types, 'Files') >= 0);
      }
    }

    render () {
      return (
        <div className="CourseImagePicker"
          onDrop={this.onDrop}
          onDragLeave={this.onDragLeave}
          onDragOver={this.onDragEnter}
          onDragEnter={this.onDragEnter}>
          { this.props.uploadingImage ?
            <div className="CourseImagePicker__Overlay">
              <Spinner title="Loading"/>
            </div>
            :
            null
          }
          { this.state.draggingFile ?
            <div className="DraggingOverlay CourseImagePicker__Overlay">
              <div className="DraggingOverlay__Content">
                <div className="DraggingOverlay__Icon">
                  <i className="icon-upload" />
                </div>
                <div className="DraggingOverlay__Instructions">
                  {I18n.t('Drop Image')}
                </div>
              </div>
            </div>
            :
            null
          }
          <div className="ic-Action-header CourseImagePicker__Header">
            <h3 className="ic-Action-header__Heading">{I18n.t('Change Image')}</h3>
            <div className="ic-Action-header__Secondary">
              <button
                className="CourseImagePicker__CloseBtn"
                onClick={this.props.handleClose}
                type="button"
              >
                <i className="icon-x" />
                <span className="screenreader-only">
                  {I18n.t('Close')}
                </span>
              </button>
            </div>
          </div>
          <div className="CourseImagePicker__Content">
            <UploadArea 
              courseId={this.props.courseId}
              handleFileUpload={this.props.handleFileUpload}/>
            <FlickrSearch selectImage={(flickrUrl) => this.props.handleFlickrUrlUpload(flickrUrl)} />
          </div>
        </div>
      );
    }
  }

  return CourseImagePicker;

});