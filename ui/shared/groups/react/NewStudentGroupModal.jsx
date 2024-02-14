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

import React, {useCallback, useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {array, bool, func, number, shape} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {throttle} from 'lodash'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import CanvasMultiSelect from '@canvas/multi-select'
import doFetchApi from '@canvas/do-fetch-api-effect'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('student_groups')

export default function NewStudentGroupModal({userCollection, loadMore, onSave, ...modalProps}) {
  const [name, setName] = useState('')
  const [users, setUsers] = useState([])
  const [userIds, setUserIds] = useState([])
  const [joinLevel, setJoinLevel] = useState('parent_context_auto_join')
  const [status, setStatus] = useState(null)
  const throttledFetchMoreUsers = useCallback(throttle(loadMore, 200), [])

  useEffect(() => {
    if (userCollection.length) {
      setUsers(userCollection.toJSON().filter(u => u.id !== ENV.current_user_id))
    } else loadMore()
    if (!modalProps.open) resetState()
  }, [loadMore, modalProps.open, userCollection])

  function handleSend() {
    const payload = {group: {name, join_level: joinLevel}, invitees: userIds.flat()}
    setStatus('info')
    doFetchApi({
      method: 'POST',
      path: `/courses/${ENV.course_id}/groups`,
      body: payload,
    })
      .then(notifyDidSave)
      .catch(err => {
        console.error(err) // eslint-disable-line no-console
        captureException(err)
        setStatus('error')
      })
  }

  function notifyDidSave() {
    showFlashSuccess(I18n.t('Created group: %{group_name}', {group_name: name}))()
    modalProps.onDismiss()
    onSave()
  }

  function resetState() {
    setName('')
    setStatus(null)
  }

  function Footer() {
    const saveButtonState = name.length === 0 || status === 'info' ? 'disabled' : 'enabled'
    return (
      <>
        <Button onClick={modalProps.onDismiss}>{I18n.t('Cancel')}</Button>
        <Button
          type="submit"
          interaction={saveButtonState}
          color="primary"
          margin="0 0 0 x-small"
          onClick={handleSend}
        >
          {I18n.t('Submit')}
        </Button>
      </>
    )
  }

  let alertMessage = ''
  if (status === 'info') alertMessage = I18n.t('Saving group')
  else if (status === 'error') alertMessage = I18n.t('An error occurred when saving the group.')

  const alert = alertMessage ? (
    <Alert variant={status}>
      {status === 'error' ? (
        <div role="alert" aria-live="assertive" aria-atomic={true}>
          {alertMessage}
        </div>
      ) : (
        <Spinner renderTitle={alertMessage} size="x-small" />
      )}
    </Alert>
  ) : null

  const newStudentGroupDescription = I18n.t(
    `Groups are a good place to collaborate on projects or to figure out schedules for study
    sessions and the like.  Every group gets a calendar, a wiki, discussions, and a little bit of
    space to store files.  Groups can collaborate on documents, or even schedule web conferences.
    It's really like a mini-course where you can work with a smaller number of students on a
    more focused project.`
  )

  const setOptionIds = optionIds => {
    if (optionIds) setUserIds(optionIds)
  }

  const multiSelectSearch = {
    options: users.map(user => ({id: user.id, text: user.name})),
  }

  const onScroll = event => {
    const {scrollTop, scrollHeight, clientHeight} = event.target
    // Subtract the scrolled height from the total scrollable height.
    // If this is equal to the visible area, you've reached the bottom.
    if (scrollHeight - scrollTop === clientHeight) {
      throttledFetchMoreUsers()
    }
  }

  return (
    <CanvasModal
      label={I18n.t('New Student Group')}
      size="medium"
      shouldCloseOnDocumentClick={false}
      footer={<Footer />}
      onScroll={onScroll}
      {...modalProps}
    >
      <FormFieldGroup
        description={
          <ScreenReaderContent>{I18n.t('New Student Group Description')}</ScreenReaderContent>
        }
        layout="stacked"
        rowSpacing="small"
      >
        <Flex direction="column" margin="none">
          <Flex.Item padding="small">
            <Text>{newStudentGroupDescription}</Text>
          </Flex.Item>
          <Flex.Item padding="small">
            <TextInput
              id="group-name"
              renderLabel={I18n.t('Group Name')}
              value={name}
              onChange={(_event, value) => setName(value)}
              isRequired={true}
            />
          </Flex.Item>
          <Flex.Item padding="small">
            <SimpleSelect
              id="join-level-select"
              renderLabel={I18n.t('Joining')}
              defaultValue="parent_context_auto_join"
              value={joinLevel}
              onChange={(_event, input) => setJoinLevel(input.value)}
            >
              <SimpleSelect.Option id="parent_context_auto_join" value="parent_context_auto_join">
                {I18n.t('Course members are free to join')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="invitation_only" value="invitation_only">
                {I18n.t('Membership by invitation only')}
              </SimpleSelect.Option>
            </SimpleSelect>
          </Flex.Item>
          <Flex.Item padding="small">
            <CanvasMultiSelect
              id="invite-filter"
              label={I18n.t('Invite Students')}
              placeholder={I18n.t('Search')}
              selectedOptionIds={userIds}
              disabled={users.length === 0}
              onChange={optionIds => setOptionIds(optionIds)}
              customRenderBeforeInput={tags =>
                [<IconSearchLine key="search-icon" />].concat(tags || [])
              }
              matchStrategy="substring"
            >
              {multiSelectSearch.options.map(option => (
                <CanvasMultiSelect.Option id={option.id} key={option.id} value={option.id}>
                  {option.text}
                </CanvasMultiSelect.Option>
              ))}
            </CanvasMultiSelect>
          </Flex.Item>
        </Flex>
      </FormFieldGroup>
      {alert}
    </CanvasModal>
  )
}

NewStudentGroupModal.propTypes = {
  userCollection: shape({
    length: number.isRequired,
    models: array.isRequired,
  }),
  loadMore: func.isRequired,
  onSave: func.isRequired,
  modalProps: shape({
    open: bool.isRequired,
    onDismiss: func.isRequired,
  }),
}
