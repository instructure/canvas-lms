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
import PropTypes from 'prop-types'
import Cropper from '@instructure/react-crop'
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
    imgFile: Cropper.propTypes.image, // selected image file object
    width: PropTypes.number, // desired cropped width
    height: PropTypes.number, // desired cropped height
    onImageLoaded: PropTypes.func, // if you care when the image is loaded
  }

  static defaultProps = {
    imgFile: null,
    width: 270,
    height: 270,
    onImageLoaded: null,
  }

  constructor(/* props */) {
    super()
    this.onImageLoaded = this.imageLoaded.bind(this)
    this.wrapper = null
    this.cropper = null
  }

  componentDidMount() {
    if (this.wrapper) {
      this.wrapper.focus()
    }
  }

  // called when the image is loaded in the DOM
  // @param img: the img DOM element
  imageLoaded(img) {
    if (typeof this.props.onImageLoaded === 'function') {
      this.props.onImageLoaded(img)
    }
  }

  // @returns a Promise that resolves with cropped image as a blob
  crop() {
    return this.cropper.cropImage()
  }

  render() {
    return (
      <div
        className="CanvasCropper"
        ref={el => {
          this.wrapper = el
        }}
        // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
        tabIndex="0"
      >
        {this.props.imgFile && (
          <div>
            <Cropper
              ref={el => {
                this.cropper = el
              }}
              image={this.props.imgFile}
              width={this.props.width}
              height={this.props.height}
              minConstraints={[16, 16]}
              onImageLoaded={this.onImageLoaded}
            />
          </div>
        )}
      </div>
    )
  }
}
export default CanvasCropper
