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
import IconMoreLine from 'instructure-icons/lib/Line/IconMoreLine'
import IconEditLine from 'instructure-icons/lib/Line/IconEditLine'
import IconTrashLine from 'instructure-icons/lib/Line/IconTrashLine'
import Button from '@instructure/ui-core/lib/components/Button'
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu'
import {MenuItem} from '@instructure/ui-core/lib/components/Menu'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Modal from '../../shared/components/InstuiModal'
import I18n from 'i18n!course_images'
import Actions from '../actions'
import CourseImagePicker from './CourseImagePicker'

export default class CourseImageSelector extends React.Component {
  constructor (props) {
    super(props)
    this.state = props.store.getState()
  }

  componentWillMount() {
    this.props.store.subscribe(this.handleChange)
    this.props.store.dispatch(Actions.getCourseImage(this.props.courseId))
    this.setState({gettingImage: true})
    this.mountHere = document.createElement('span');
    this.mountHere.setAttribute('style', 'position:absolute; z-index: 9999;');
    document.body.appendChild(this.mountHere);
  }

  handleChange = () => this.setState(this.props.store.getState())
  handleModalClose = () => this.props.store.dispatch(Actions.setModalVisibility(false))
  changeImage = () => this.props.store.dispatch(Actions.setModalVisibility(true))
  removeImage = () => this.props.store.dispatch(Actions.putRemoveImage(this.props.courseId))

  render() {
    return (
      <div>
        <div
          className="CourseImageSelector"
          style={this.state.imageUrl ? {backgroundImage: `url(${this.state.imageUrl})`} : {}}
        >
          {this.state.gettingImage || this.state.removingImage ? (
            <div className="CourseImageSelector__Overlay">
              <Spinner title="Loading" size="small" />
            </div>
          ) : this.state.imageUrl ? (
            <PopoverMenu
              trigger={
                <div className="CourseImageSelector__Button">
                  <Button size="small" variant="circle-primary">
                    <IconMoreLine title={I18n.t('Course image settings')} />
                  </Button>
                </div>
              }
            >
              <MenuItem onClick={this.changeImage}>
                <IconEditLine /> {I18n.t('Choose image')}</MenuItem>
              <MenuItem onClick={this.removeImage}>
                <IconTrashLine /> {I18n.t('Remove image')}</MenuItem>
            </PopoverMenu>
          ) : (
            <Button onClick={this.changeImage}>{I18n.t('Choose Image')}</Button>
          )}
        </div>
        <Modal
          open={this.state.showModal}
          size="fullscreen"
          label={I18n.t('Choose Image')}
          onDismiss={this.handleModalClose}
          mountNode={this.mountHere}
        >
          <CourseImagePicker
            courseId={this.props.courseId}
            handleClose={this.handleModalClose}
            handleFileUpload={(e, courseId) => this.props.store.dispatch(Actions.uploadFile(e, courseId))}
            handleFlickrUrlUpload={flickrUrl => this.props.store.dispatch(Actions.uploadFlickrUrl(flickrUrl, this.props.courseId))}
            uploadingImage={this.state.uploadingImage}
          />
        </Modal>
      </div>
    )
  }
}
