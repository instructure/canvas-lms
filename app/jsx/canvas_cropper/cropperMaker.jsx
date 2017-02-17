define([
  'react',
  'react-dom',
  './cropper'
], (React, ReactDOM, CanvasCropper) => {
  // CanvasCropperMaker is the component you'll create if injecting the cropper
  // into existing non-react UI (see UploadFileView.coffee for sample usage)
  //  let cropper = new Cropper(@$('.avatar-preview')[0], {imgFile: @file, width: @avatarSize.w, height: @avatarSize.h})
  //  cropper.render()
  //
  class CanvasCropperMaker {
    // @param root: DOM node where I want the cropper created
    // @param props: properties
    //    imgFile: the File object returned from the native file open dialog
    //    width: desired width in px of the final cropped image
    //    height: desired height in px if the final cropped image
    constructor (root, props) {
      this.root = root;                     // DOM node we render into
      this.imgFile = props.imgFile;
      this.width = props.width || 128;
      this.height = props.width || 128;
      this.cropper = null;
    }
    unmount () {
      ReactDOM.unmountComponentAtNode(this.root);
    }
    render () {
      ReactDOM.render(
        <CanvasCropper ref={(el) => { this.cropper = el }} imgFile={this.imgFile} width={this.width} height={this.height} />,
        this.root
      )
    }
    // crop the image.
    // returns a promise that resolves with the cropped image as a blob
    crop () {
      return this.cropper
        ? this.cropper.crop()
        : null;
    }
  }
  return CanvasCropperMaker;
});
