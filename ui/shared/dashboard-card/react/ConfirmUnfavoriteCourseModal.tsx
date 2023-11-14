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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ReactDOM from 'react-dom'

import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'

const I18n = useI18nScope('dashcards')

export function showConfirmUnfavorite(props: Props) {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'confirm-unfavorite-modal-container')
  document.body.appendChild(parent)

  function showConfirmUnfavoriteRef(modal: null | {show: () => void}) {
    if (modal) modal.show()
  }

  ReactDOM.render(
    <ConfirmUnfavoriteCourseModal {...props} ref={showConfirmUnfavoriteRef} />,
    parent
  )
  return parent
}

export function hideConfirmModal(modal: {hide: () => void}) {
  modal.hide()
}

export function showNoFavoritesAlert() {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'no-favorites-alert-container')
  document.querySelector('.ic-DashboardCard__box')?.appendChild(parent)

  ReactDOM.render(
    <Alert variant="info" renderCloseButtonLabel="Close" margin="small">
      {I18n.t(`You have no courses favorited. Reloading this page will show all
      your active courses. To add favorites, go to `)}{' '}
      <a href="/courses">{I18n.t('All Courses.')}</a>
    </Alert>,
    parent
  )
  return parent
}

type Props = {
  courseName: string
  onConfirm: () => void
  onClose: () => void
  onEntered: () => void
}

type State = {
  show: boolean
}

export default class ConfirmUnfavoriteCourseModal extends React.Component<Props, State> {
  static defaultProps = {
    onConfirm: null,
    onClose() {},
    onEntered() {},
  }

  constructor(props: Props) {
    super(props)
    this.state = {
      show: false,
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
          <CloseButton
            placement="end"
            offset="medium"
            onClick={this.hide}
            screenReaderLabel="\n            Close\n          "
          />
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
            color="primary"
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
