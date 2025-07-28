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

import React, {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {bool, func, shape} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {captureException} from '@sentry/react'
import StudentMultiSelect from './components/StudentMultiSelect'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'

const I18n = createI18nScope('student_groups')

export default function NewStudentGroupModal({onSave, ...modalProps}) {
  const [name, setName] = useState('')
  const [userIds, setUserIds] = useState([])
  const [joinLevel, setJoinLevel] = useState('parent_context_auto_join')
  const [status, setStatus] = useState(null)
  const [nameValidationMessages, setNameValidationMessages] = useState([
    {text: '', type: 'success'},
  ])

  useEffect(() => {
    if (!modalProps.open) resetState()
  }, [modalProps.open])

  const validateName = (newName, shouldFocus) => {
    if (newName.trim().length === 0) {
      const nameErrorText = I18n.t('A group name is required.')
      setNameValidationMessages([{text: nameErrorText, type: 'newError'}])
      if (shouldFocus) {
        const input = document.getElementById(`group-name`)
        input?.focus()
        shouldFocus = false
      }
      return false
    } else if (newName.length > 255) {
      const nameErrorText = I18n.t('Group name must be less than 255 characters.')
      setNameValidationMessages([{text: nameErrorText, type: 'newError'}])
      if (shouldFocus) {
        const input = document.getElementById(`group-name`)
        input?.focus()
        shouldFocus = false
      }
      return false
    } else {
      setNameValidationMessages([{text: '', type: 'success'}])
      return true
    }
  }

  const validateFormFields = (shouldFocus = false) => {
    return validateName(name, shouldFocus)
  }

  function handleSend() {
    if (validateFormFields(true)) {
      const payload = {group: {name, join_level: joinLevel}, invitees: userIds.flat()}
      setStatus('info')
      doFetchApi({
        method: 'POST',
        path: `/courses/${ENV.course_id}/groups`,
        body: payload,
      })
        .then(notifyDidSave)
        .catch(err => {
          console.error(err)
          captureException(err)
          setStatus('error')
        })
    }
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
    return (
      <>
        <Button onClick={modalProps.onDismiss}>{I18n.t('Cancel')}</Button>
        <Button type="submit" color="primary" margin="0 0 0 x-small" onClick={handleSend}>
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
    more focused project.`,
  )

  const setOptionIds = optionIds => {
    if (optionIds) setUserIds(optionIds)
  }

  return (
    <QueryClientProvider client={queryClient}>
      <CanvasModal
        label={I18n.t('New Student Group')}
        size="medium"
        shouldCloseOnDocumentClick={false}
        footer={<Footer />}
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
                onChange={(_event, value) => {
                  setName(value)
                }}
                onBlur={e => {
                  validateName(e.target.value)
                }}
                isRequired={true}
                messages={nameValidationMessages}
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
              <StudentMultiSelect
                selectedOptionIds={userIds}
                onSelect={optionIds => setOptionIds(optionIds)}
              />
            </Flex.Item>
          </Flex>
        </FormFieldGroup>
        {alert}
      </CanvasModal>
    </QueryClientProvider>
  )
}

NewStudentGroupModal.propTypes = {
  onSave: func.isRequired,
  modalProps: shape({
    open: bool.isRequired,
    onDismiss: func.isRequired,
  }),
}
