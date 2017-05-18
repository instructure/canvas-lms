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
import Modal from 'react-modal'
import I18n from 'i18n!course_images'
import Actions from '../actions'
import CourseImagePicker from './CourseImagePicker'
import Spinner from 'instructure-ui/lib/components/Spinner'

  const modalOverrides = {
    content : {
      position: 'absolute',
      top: '0',
      left: '0',
      right: '0',
      bottom: '0',
      border: 'none',
      padding: '12px',
      maxWidth: '1420px',
      borderRadius: '0',
      background: '#ffffff'
    }
  };

  class CourseImageSelector extends React.Component {

    constructor (props) {
      super(props);
      this.state = props.store.getState();

      this.handleChange = this.handleChange.bind(this);
      this.handleModalClose = this.handleModalClose.bind(this);
      this.changeImage = this.changeImage.bind(this);
      this.removeImage = this.removeImage.bind(this);
    }

    componentWillMount () {
      this.props.store.subscribe(this.handleChange);
      this.props.store.dispatch(Actions.getCourseImage(this.props.courseId));
      this.setState({gettingImage: true});
    }

    handleChange () {
      this.setState(this.props.store.getState());
    }

    handleModalClose () {
      this.props.store.dispatch(Actions.setModalVisibility(false));
    }

    changeImage() {
      this.props.store.dispatch(Actions.setModalVisibility(true));
    }

    removeImage() {
      this.props.store.dispatch(Actions.putRemoveImage(this.props.courseId));
    }

    imageControls () {
      if (this.state.imageUrl) {
        return (
          <div>
            <div className="al-dropdown__container CourseImageSelector__EditDropdown">
              <a className="al-trigger" role="button" href="#">
                <i className="icon-settings"></i>
                <i className="icon-mini-arrow-down"></i>
                <span className="screenreader-only">{I18n.t('Course image settings')}</span>
              </a>

              <ul id="courseImage-editDropdown-1"
                  ref="editDropdown"
                  className="al-options"
                  role="menu"
                  tabIndex="0"
                  aria-hidden="true"
                  aria-expanded="false"
                  aria-activedescendant="courseImage-editDropdown-2"
              >
                <li role="presentation">
                  <a href="#"
                     onClick={() => this.changeImage()}
                     className="icon-compose icon-Line"
                     id="courseImage-editDropdown-2"
                     tabIndex="-1"
                     ref="changeImage"
                     role="menuitem"
                  >
                    {I18n.t('Change image')}
                  </a>
                </li>
                <li role="presentation">
                  <a href="#"
                     onClick={() => this.removeImage()}
                     className="icon-trash"
                     id="courseImage-editDropdown-3"
                     tabIndex="-1"
                     ref="removeImage"
                     role="menuitem"
                  >
                     {I18n.t('Remove image')}
                  </a>
                </li>
              </ul>
            </div>
          </div>
        );
      }
      else {
        return (
          <button
            className="Button"
            type="button"
            onClick={() => this.props.store.dispatch(Actions.setModalVisibility(true))}
          >
            {I18n.t('Choose Image')}
          </button>
        );
      }
    }

    render () {

      const styles = {
        backgroundImage: `url(${this.state.imageUrl})`
      };

      return (
        <div>
          <div
            className="CourseImageSelector"
            style={(this.state.imageUrl) ? styles : {}}
          >
            { this.state.gettingImage || this.state.removingImage ?
              <div className="CourseImageSelector__Overlay">
                <Spinner title="Loading" size="small" />
              </div>
              :
              this.imageControls()
            }
          </div>
          <Modal
            isOpen={this.state.showModal}
            onRequestClose={this.handleModalClose}
            style={modalOverrides}
          >
            <CourseImagePicker
              courseId={this.props.courseId}
              handleClose={this.handleModalClose}
              handleFileUpload={(e, courseId) => this.props.store.dispatch(Actions.uploadFile(e, courseId))}
              handleFlickrUrlUpload={(flickrUrl) => this.props.store.dispatch(Actions.uploadFlickrUrl(flickrUrl, this.props.courseId))}
              uploadingImage={this.state.uploadingImage}
            />
          </Modal>
        </div>
      );
    }
  };

export default CourseImageSelector
