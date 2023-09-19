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
import {IconMoreLine, IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Spinner} from '@instructure/ui-spinner'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {useScope as useI18nScope} from '@canvas/i18n'
import Actions from '../actions'
import CourseImagePicker from './CourseImagePicker'

const I18n = useI18nScope('course_images')

let overflow = ''

export default class CourseImageSelector extends React.Component {
  static propTypes = {
    courseId: PropTypes.string.isRequired,
    setting: PropTypes.string.isRequired,
    store: PropTypes.object.isRequired,
    wide: PropTypes.bool,
  }

  static defaultProps = {
    wide: false,
  }

  state = this.props.store.getState()

  UNSAFE_componentWillMount() {
    this.props.store.subscribe(() => this.setState(this.props.store.getState()))
    this.props.store.dispatch(Actions.getCourseImage(this.props.courseId, this.props.setting))
    this.setState({gettingImage: true})
  }

  handleModalOpen = () => {
    overflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
  }

  handleModalClose = () => {
    document.body.style.overflow = overflow
  }

  handleModalDismiss = () => {
    this.props.store.dispatch(Actions.setModalVisibility(false))
  }

  changeImage = () => this.props.store.dispatch(Actions.setModalVisibility(true))

  removeImage = () =>
    this.props.store.dispatch(Actions.putRemoveImage(this.props.courseId, this.props.setting))

  render() {
    return (
      <div className={`CourseImageSelectorWrapper ${this.props.wide ? 'wide' : ''}`}>
        <div className="CourseImageSelectorContent">
          <div
            className="CourseImageSelector"
            style={this.state.imageUrl ? {backgroundImage: `url(${this.state.imageUrl})`} : {}}
          >
            {this.state.gettingImage || this.state.removingImage ? (
              <div className="CourseImageSelector__Overlay">
                <Spinner renderTitle="Loading" size="small" />
              </div>
            ) : this.state.imageUrl ? (
              <Menu
                trigger={
                  <div className="CourseImageSelector__Button">
                    <Button
                      themeOverride={{
                        primaryBorderColor: '#fff',
                        borderWidth: '1px',
                        borderStyle: 'solid',
                      }}
                      size="small"
                      color="primary"
                      shape="circle"
                      label={I18n.t('Course image settings')}
                      aria-label={I18n.t('Course image settings')}
                    >
                      <IconMoreLine />
                    </Button>
                  </div>
                }
              >
                <Menu.Item onClick={this.changeImage}>
                  <IconEditLine /> {I18n.t('Choose image')}
                </Menu.Item>
                <Menu.Item onClick={this.removeImage}>
                  <IconTrashLine /> {I18n.t('Remove image')}
                </Menu.Item>
              </Menu>
            ) : (
              <Button onClick={this.changeImage}>{I18n.t('Choose Image')}</Button>
            )}
          </div>
        </div>
        <Modal
          open={this.state.showModal}
          size="fullscreen"
          label={I18n.t('Choose Image')}
          onDismiss={this.handleModalDismiss}
          onEnter={this.handleModalOpen}
          onExit={this.handleModalClose}
          onDragOver={e => e.preventDefault()}
          onDrop={e => e.preventDefault()}
        >
          <Modal.Body>
            <CourseImagePicker
              courseId={this.props.courseId}
              handleClose={this.handleModalClose}
              handleFileUpload={(e, courseId) =>
                this.props.store.dispatch(Actions.uploadFile(e, courseId, this.props.setting))
              }
              uploadingImage={this.state.uploadingImage}
            />
          </Modal.Body>
        </Modal>
      </div>
    )
  }
}
