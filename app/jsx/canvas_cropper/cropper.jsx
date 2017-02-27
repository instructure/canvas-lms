define([
  'react',
  'react-crop'
], (React, {default: Cropper}) => {
  //
  // The react-crop component requires a wrapper component for interacting
  // with the outside world.
  // The main thing you have to do is set style for .CanvasCropper
  // For example, the style for profile avatars looks like
  // .avatar-preview .CanvasCropper {
  //   max-width: 270px;
  //   max-height: 270px;
  //   overflow: hidden;
  // }
  //
  class CanvasCropper extends React.Component {

    static propTypes = {
      imgFile: React.PropTypes.object,    // eslint-disable-line react/forbid-prop-types
                                          // selected image file object
      width: React.PropTypes.number,      // desired cropped width
      height: React.PropTypes.number,     // desired cropped height
      onImageLoaded: React.PropTypes.func // if you care when the image is loaded
    };
    static defaultProps = {
      imgFile: null,
      width: 270,
      height: 270,
      onImageLoaded: null
    };

    constructor (/* props */) {
      super();
      this.onImageLoaded = this.imageLoaded.bind(this);
      this.wrapper = null;
      this.cropper = null;
    }

    componentDidMount () {
      if (this.wrapper) {
        this.wrapper.focus()
      }
    }

    // called when the image is loaded in the DOM
    // @param img: the img DOM element
    imageLoaded (img) {
      if (typeof this.props.onImageLoaded === 'function') {
        this.props.onImageLoaded(img);
      }
    }

    // @returns a Promise that resolves with cropped image as a blob
    crop () {
      return this.cropper.cropImage();
    }

    render () {
      return (
        <div className="CanvasCropper" ref={(el) => { this.wrapper = el }} tabIndex="0">
          {this.props.imgFile &&
            <div>
              <Cropper
                ref={(el) => { this.cropper = el }}
                image={this.props.imgFile}
                width={this.props.width}
                height={this.props.height}
                minConstraints={[16, 16]}
                onImageLoaded={this.onImageLoaded}
              />
            </div>}
        </div>
      )
    }
  }
  return CanvasCropper;
});
