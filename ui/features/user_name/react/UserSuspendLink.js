/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import React, {useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('user_name')

const SUSPEND = 'suspend'
const REACTIVATE = 'unsuspend'
const CUSTOM_EVENT = 'username:pseudonymstatuschange'

function linksToShow() {
  if (ENV && typeof ENV.user_suspend_status === 'undefined') return []
  const pseuds = ENV.user_suspend_status.pseudonyms
  const result = []
  if (pseuds.some(e => e.workflow_state !== 'suspended')) result.push(SUSPEND)
  if (pseuds.some(e => e.workflow_state === 'suspended')) result.push(REACTIVATE)
  return result
}

const notifyEvents = {
  [SUSPEND]: new CustomEvent(CUSTOM_EVENT, {detail: {action: SUSPEND}}),
  [REACTIVATE]: new CustomEvent(CUSTOM_EVENT, {detail: {action: REACTIVATE}}),
}

export default function UserSuspendLink() {
  const [show, setShow] = useState(linksToShow)
  const [selectedAction, setSelectedAction] = useState(SUSPEND)
  const [modalIsOpen, setModalIsOpen] = useState(false)

  // TODO:  the user's pseudonyms are listed along with their suspended status
  // in a different section of this page. Unfortunately that other section is
  // currently controlled by a totally different JS bundle and a bunch of jQuery
  // code. So while we have to get it to update those pseudonyms, we have no way
  // of directly communicating with that other code. So for now we will just use
  // a CustomEvent and use window as the communication bus. For the other end of
  // this communication channel, see ui/features/user_logins/jquery/index.js
  //
  // Eventually both bundles should be rewritten into one larger tree of React
  // components, and then this can be redone in more standard ways.
  function crossNotify(action) {
    window.dispatchEvent(notifyEvents[action])
  }

  async function handleAction(action) {
    try {
      await doFetchApi({
        path: `/api/v1/users/${ENV.USER_ID}`,
        method: 'PUT',
        body: {user: {event: action}},
      })
      setShow([action === SUSPEND ? REACTIVATE : SUSPEND]) // show opposite action now
      crossNotify(action)
    } catch (err) {
      const message =
        action === SUSPEND
          ? I18n.t("Could not suspend this user's access")
          : I18n.t("Could not reactivate this user's access")
      showFlashAlert({message, err, type: 'error'})
    } finally {
      setModalIsOpen(false)
    }
  }

  function handleClick(action) {
    setSelectedAction(action)
    setModalIsOpen(true)
  }

  function renderSuspendLink() {
    return (
      <Link isWithinText={false} onClick={handleClick.bind(null, SUSPEND)}>
        {I18n.t('Suspend User')}
      </Link>
    )
  }

  function renderReactivateLink() {
    return (
      <Link isWithinText={false} onClick={handleClick.bind(null, REACTIVATE)}>
        {I18n.t('Reactivate User')}
      </Link>
    )
  }

  function renderInfoText(infoText) {
    return (
      <>
        <br />
        <Text as="div">{infoText}</Text>
      </>
    )
  }

  function onModalCancel() {
    setModalIsOpen(false)
  }

  function renderModal(action) {
    const name = ENV.CONTEXT_USER_DISPLAY_NAME
    let modalLabel, actionColor, actionFunc, actionName, actionText, infoText
    if (action === SUSPEND) {
      modalLabel = I18n.t('Confirm suspension')
      actionColor = 'danger'
      actionFunc = handleAction.bind(null, SUSPEND)
      actionName = I18n.t('Suspend')
      actionText = I18n.t(
        'Suspending %{name} from this account will remove all access to all authorized systems from all their logins.',
        {name}
      )
      infoText = I18n.t(
        'You must be authorized to manage SIS in order to suspend logins with an associated SIS ID.'
      )
    } else {
      modalLabel = I18n.t('Confirm reactivation')
      actionColor = 'primary'
      actionFunc = handleAction.bind(null, REACTIVATE)
      actionName = 'Reactivate'
      actionText = I18n.t(
        'Reactivation will allow all logins for %{name} to log in to Canvas and regain access to previously authorized API integrations.',
        {name}
      )
      infoText = I18n.t(
        'You must be authorized to manage SIS in order to reactivate logins with an associated SIS ID.'
      )
    }
    return (
      <Modal size="small" open={modalIsOpen} onDismiss={onModalCancel} label={modalLabel}>
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            onClick={onModalCancel}
            screenReaderLabel={I18n.t('Cancel')}
          />
          <Heading>{modalLabel}</Heading>
        </Modal.Header>

        <Modal.Body>
          <View as="div" margin="medium">
            <Text as="div">{actionText}</Text>
            {ENV.PERMISSIONS.can_manage_sis_pseudonyms ? null : renderInfoText(infoText)}
          </View>
        </Modal.Body>

        <Modal.Footer>
          <Button
            margin="none x-small"
            color="secondary"
            onClick={onModalCancel}
            data-testid="cancel-button"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            margin="none x-small"
            color={actionColor}
            onClick={actionFunc}
            data-testid="action-button"
          >
            {actionName}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }

  return (
    <>
      {show.includes(SUSPEND) && renderSuspendLink()}
      {show.length === 2 && ' | '}
      {show.includes(REACTIVATE) && renderReactivateLink()}
      {show.length > 0 && renderModal(selectedAction)}
    </>
  )
}
