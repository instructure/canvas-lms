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
import IconMoreLine from '@instructure/ui-icons/lib/Line/IconMore'
import IconEditLine from '@instructure/ui-icons/lib/Line/IconEdit'
import IconTrashLine from '@instructure/ui-icons/lib/Line/IconTrash'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Menu, {MenuItem} from '@instructure/ui-menu/lib/components/Menu'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Modal from '../../shared/components/InstuiModal'
import I18n from 'i18n!course_images'
import Actions from '../actions'
import CourseImagePicker from './CourseImagePicker'

export default class CourseImageSelector extends React.Component {
  state = this.props.store.getState()

  componentWillMount() {
    this.props.store.subscribe(() => this.setState(this.props.store.getState()))
    this.props.store.dispatch(Actions.getCourseImage(this.props.courseId))
    this.setState({gettingImage: true})
  }

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
            <Menu
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
            </Menu>
          ) : (
            <Button onClick={this.changeImage}>{I18n.t('Choose Image')}</Button>
          )}
        </div>
        <Modal
          open={this.state.showModal}
          size="fullscreen"
          label={I18n.t('Choose Image')}
          onDismiss={this.handleModalClose}
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
