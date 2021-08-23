/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from 'i18n!dashcards'
import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'

export function showConfirmUnfavorite(props) {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'confirm-unfavorite-modal-container')
  document.body.appendChild(parent)

  function showConfirmUnfavoriteRef(modal) {
    if (modal) modal.show()
  }

  ReactDOM.render(
    <ConfirmUnfavoriteCourseModal {...props} parent={parent} ref={showConfirmUnfavoriteRef} />,
    parent
  )
  return parent
}

export function hideConfirmModal(modal) {
  modal.hide()
}

export function showNoFavoritesAlert() {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'no-favorites-alert-container')
  document.querySelector('.ic-DashboardCard__box').appendChild(parent)

  ReactDOM.render(
    <Alert
      variant="info"
      closeButtonLabel="Close"
      label={I18n.t('No courses favorited')}
      margin="small"
    >
      {I18n.t(`You have no courses favorited. Reloading this page will show all
      your active courses. To add favorites, go to `)}{' '}
      <a href="/courses">{I18n.t('All Courses.')}</a>
    </Alert>,
    parent
  )
  return parent
}

export default class ConfirmUnfavoriteCourseModal extends React.Component {
  static propTypes = {
    courseName: PropTypes.string.isRequired,
    onConfirm: PropTypes.func.isRequired,
    onClose: PropTypes.func,
    onEntered: PropTypes.func
  }

  static defaultProps = {
    onConfirm: null,
    onClose() {},
    onEntered() {}
  }

  constructor(props) {
    super(props)
    this.state = {
      show: false
    }

    this.hide = this.hide.bind(this)
    this.handleSubmitUnfavorite = this.handleSubmitUnfavorite.bind(this)
  }

  show() {
    this.setState({show: true})
  }

  hide() {
    this.setState({show: false})
  }

  handleSubmitUnfavorite() {
    this.props.onConfirm()
    this.hide()
  }

  render() {
    return (
      <Modal
        label={I18n.t('Confirm unfavorite course')}
        onDismiss={this.hide}
        onEntered={this.props.onEntered}
        onExit={this.props.onClose}
        open={this.state.show}
        size="small"
      >
        <Modal.Header>
          <CloseButton placement="end" offset="medium" variant="icon" onClick={this.hide}>
            Close
          </CloseButton>
          <Heading>
            {I18n.t(`Unfavorite %{courseName}`, {courseName: this.props.courseName})}
          </Heading>
        </Modal.Header>

        <Modal.Body>
          {I18n.t(
            `You are about to remove this course from your dashboard. It will still be available
              by navigating to Courses > All Courses from the main menu.`
          )}
        </Modal.Body>

        <Modal.Footer>
          <Button id="cancel_unfavorite_course" onClick={this.hide} margin="0 x-small 0 0">
            {I18n.t('Close')}
          </Button>
          <Button
            variant="primary"
            id="confirm_unfavorite_course"
            onClick={this.handleSubmitUnfavorite}
          >
            {I18n.t('Submit')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}
