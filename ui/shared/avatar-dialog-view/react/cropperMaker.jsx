/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import ReactDOM from 'react-dom'
import CanvasCropper from './cropper'

// CanvasCropperMaker is the component you'll create if injecting the cropper
// into existing non-react UI (see UploadFileView.js for sample usage)
//  let cropper = new Cropper(@$('.avatar-preview')[0], {imgFile: @file, width: @avatarSize.w, height: @avatarSize.h})
//  cropper.render()
//
class CanvasCropperMaker {
  // @param root: DOM node where I want the cropper created
  // @param props: properties
  //    imgFile: the File object returned from the native file open dialog
  //    width: desired width in px of the final cropped image
  //    height: desired height in px of the final cropped image
  constructor(root, props) {
    this.root = root // DOM node we render into
    this.imgFile = props.imgFile
    this.onImageLoaded = props.onImageLoaded
    this.width = props.width || 128
    this.height = props.height || 128
    this.cropper = null
  }

  unmount() {
    ReactDOM.unmountComponentAtNode(this.root)
  }

  render() {
    ReactDOM.render(
      <CanvasCropper
        height={this.height}
        imgFile={this.imgFile}
        onImageLoaded={this.onImageLoaded}
        ref={el => {
          this.cropper = el
        }}
        width={this.width}
      />,
      this.root
    )
  }

  // crop the image.
  // returns a promise that resolves with the cropped image as a blob
  crop() {
    return this.cropper ? this.cropper.crop() : null
  }
}
export default CanvasCropperMaker
