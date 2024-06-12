/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import React, {useState, useEffect, useCallback} from 'react'
import moment from 'moment'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../../util/utils'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Heading} from '@instructure/ui-heading'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import ModalSpinner from '../ComposeModalContainer/ModalSpinner'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import {INBOX_SETTINGS_QUERY} from '../../../graphql/Queries'
import {UPDATE_INBOX_SETTINGS} from '../../../graphql/Mutations'
import {useQuery, useMutation} from 'react-apollo'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import useInboxSettingsValidate from '../../hooks/useInboxSettingsValidate'
import type {InboxSettings, InboxSettingsData} from '../../../inboxModel'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = useI18nScope('conversations_2')

export interface Props {
  inboxSignatureBlock: boolean
  inboxAutoResponse: boolean
  onDismissWithAlert: (arg?: string) => void
}

export const SAVE_SETTINGS_OK = 'SAVE_SETTINGS_OK'
export const SAVE_SETTINGS_FAIL = 'SAVE_SETTINGS_FAIL'
export const LOAD_SETTINGS_FAIL = 'LOAD_SETTINGS_FAIL'
export const defaultInboxSettings: InboxSettings = {
  useSignature: false,
  signature: '',
  useOutOfOffice: false,
  outOfOfficeFirstDate: undefined,
  outOfOfficeLastDate: undefined,
  outOfOfficeSubject: '',
  outOfOfficeMessage: '',
}

const InboxSettingsModalContainer = ({
  inboxSignatureBlock,
  inboxAutoResponse,
  onDismissWithAlert,
}: Props) => {
  const [isOpen, setIsOpen] = useState<boolean>(true)
  const [isExited, setIsExited] = useState<boolean>(false)
  const [alert, setAlert] = useState<string>('')
  const [originalFormState, setOriginalFormState] = useState<InboxSettings>(defaultInboxSettings)
  const [formState, setFormState] = useState<InboxSettings>(defaultInboxSettings)
  const [updateInboxSettings, {loading: updateInboxSettingsLoading}] = useMutation(
    UPDATE_INBOX_SETTINGS,
    {
      onCompleted: data => {
        const hasError = data?.updateMyInboxSettings?.errors?.[0]?.message
        if (hasError) {
          setAlert(SAVE_SETTINGS_FAIL)
        } else {
          setAlert(SAVE_SETTINGS_OK)
        }
        closeModal()
      },
      onError: () => {
        setAlert(SAVE_SETTINGS_FAIL)
        closeModal()
      },
    }
  )
  const timezone = ENV?.TIMEZONE || Intl.DateTimeFormat().resolvedOptions().timeZone
  const today = moment.tz(timezone).startOf('day')
  const dateFormatter: any = useDateTimeFormat('date.formats.medium_with_weekday', timezone)

  const noError: FormMessage[] = []
  const [signatureError, setSignatureError] = useState<FormMessage[]>(noError)
  const [subjectError, setSubjectError] = useState<FormMessage[]>(noError)
  const [messageError, setMessageError] = useState<FormMessage[]>(noError)
  const [firstDateError, setFirstDateError] = useState<FormMessage[]>(noError)
  const [lastDateError, setLastDateError] = useState<FormMessage[]>(noError)

  const formErrorMsg = (msg: string): FormMessage[] => [{text: msg, type: 'error'}]
  const charLimitError = formErrorMsg(I18n.t('Must be 255 characters or less'))
  const dateEmptyError = formErrorMsg(I18n.t('Date cannot be empty'))
  const datePastError = formErrorMsg(I18n.t('Date cannot be in the past'))
  const dateBeforeError = formErrorMsg(I18n.t('Date cannot be before start date'))
  const subjectEmptyError = formErrorMsg(I18n.t('Subject cannot be empty'))
  const signatureEmptyError = formErrorMsg(I18n.t('Signature cannot be empty'))

  const {
    validateForm,
    focusOnError,
    setFirstDateRef,
    setLastDateRef,
    setSubjectRef,
    setMessageRef,
    setSignatureRef,
  } = useInboxSettingsValidate()

  const {
    loading: inboxSettingsLoading,
    data: inboxSettingsData,
    error: inboxSettingsError,
  } = useQuery(INBOX_SETTINGS_QUERY)

  useEffect(() => {
    if (inboxSettingsError) {
      onDismissWithAlert(LOAD_SETTINGS_FAIL)
    }
    if (inboxSettingsData) {
      if (inboxSettingsData?.myInboxSettings === null) {
        setFormState(defaultInboxSettings)
      } else {
        const rawData = inboxSettingsData?.myInboxSettings || {}
        const filteredState = filterState(convertData(rawData))
        setFormState(filteredState)
        setOriginalFormState(filteredState)
      }
    }
  }, [inboxSettingsData, inboxSettingsError, onDismissWithAlert])

  // unmount component after modal transitions out to preserve fading effect
  useEffect(() => {
    if (isExited) onDismissWithAlert(alert)
  }, [alert, isExited, onDismissWithAlert])

  const closeModal = () => setIsOpen(false)

  const saveInboxSettings = useCallback(async () => {
    await updateInboxSettings({
      variables: {
        input: filterState(formState),
      },
    })
  }, [formState, updateInboxSettings])

  const convertData = (rawData: InboxSettingsData) => {
    const outOfOfficeFirstDate = Date.parse(String(rawData.outOfOfficeFirstDate)) || undefined
    const outOfOfficeLastDate = Date.parse(String(rawData.outOfOfficeLastDate)) || undefined
    const outOfOfficeSubject = rawData.outOfOfficeSubject || ''
    const outOfOfficeMessage = rawData.outOfOfficeMessage || ''
    const signature = rawData.signature || ''
    return {
      ...rawData,
      outOfOfficeFirstDate,
      outOfOfficeLastDate,
      outOfOfficeSubject,
      outOfOfficeMessage,
      signature,
    }
  }

  const filterState = (state: Object = defaultInboxSettings): InboxSettings => {
    const allowedKeys = new Set([
      'useSignature',
      'signature',
      'useOutOfOffice',
      'outOfOfficeFirstDate',
      'outOfOfficeLastDate',
      'outOfOfficeSubject',
      'outOfOfficeMessage',
    ])
    return Object.entries(state).reduce((acc, [key, val]) => {
      if (allowedKeys.has(key)) acc = {...acc, [key]: val}
      return acc
    }, {})
  }

  const clearOutOfOfficeErrors = () => {
    setFirstDateError(noError)
    setLastDateError(noError)
    setSubjectError(noError)
    setMessageError(noError)
  }

  const oooEnabledAndUnchanged =
    originalFormState.useOutOfOffice &&
    moment(originalFormState.outOfOfficeFirstDate).isSame(formState.outOfOfficeFirstDate) &&
    moment(originalFormState.outOfOfficeLastDate).isSame(formState.outOfOfficeLastDate) &&
    originalFormState.outOfOfficeSubject === formState.outOfOfficeSubject &&
    originalFormState.outOfOfficeMessage === formState.outOfOfficeMessage

  const validateDateEmpty = (value: Date | undefined) => (!value ? dateEmptyError : noError)

  const validateFirstDate = (value: Date | undefined) => {
    const error = validateDateEmpty(value)
    setFirstDateError(error)
    return error === noError
  }

  const validateFirstDateOnSave = () => {
    // don't validate if OOO disabled or previously enabled and unchanged
    if (!formState.useOutOfOffice || oooEnabledAndUnchanged) return true
    let error = validateDateEmpty(formState.outOfOfficeFirstDate)
    if (moment(formState.outOfOfficeFirstDate).isBefore(today)) error = datePastError
    setFirstDateError(error)
    return error === noError
  }

  const validateLastDate = (value: Date | undefined) => {
    const error = validateDateEmpty(value)
    setLastDateError(error)
    return error === noError
  }

  const validateLastDateOnSave = () => {
    // don't validate if OOO disabled or previously enabled and unchanged
    if (!formState.useOutOfOffice || oooEnabledAndUnchanged) return true
    let error = validateDateEmpty(formState.outOfOfficeLastDate)
    if (moment(formState.outOfOfficeLastDate).isBefore(today)) error = datePastError
    if (moment(formState.outOfOfficeLastDate).isBefore(moment(formState.outOfOfficeFirstDate)))
      error = dateBeforeError
    setLastDateError(error)
    return error === noError
  }

  const validateCharLimit = (str: string = '') => (str.length > 255 ? charLimitError : noError)

  const validateSubject = (subject: string = '') => {
    const error = validateCharLimit(subject)
    setSubjectError(error)
    return error === noError
  }

  const validateSubjectOnSave = () => {
    if (!formState.useOutOfOffice) return true
    const subject = formState.outOfOfficeSubject || ''
    let error = validateCharLimit(subject)
    if (subject.trim().length < 1) error = subjectEmptyError
    setSubjectError(error)
    return error === noError
  }

  const validateMessage = (message: string = '') => {
    const error = validateCharLimit(message)
    setMessageError(error)
    return error === noError
  }

  const validateMessageOnSave = () => {
    if (!formState.useOutOfOffice) return true
    const error = validateCharLimit(formState.outOfOfficeMessage)
    setMessageError(error)
    return error === noError
  }

  const validateSignature = (signature: string = '') => {
    const error = validateCharLimit(signature)
    setSignatureError(error)
    return error === noError
  }

  const validateSignatureOnSave = () => {
    if (!formState.useSignature) return true
    const signature = formState.signature || ''
    let error = validateCharLimit(signature)
    if (signature.trim().length < 1) error = signatureEmptyError
    setSignatureError(error)
    return error === noError
  }

  const onFirstDayChange = (value: Date | undefined) => {
    const outOfOfficeFirstDate = moment(value).tz(timezone).startOf('day').toDate()
    setFormState(state => ({...state, outOfOfficeFirstDate}))
    validateFirstDate(outOfOfficeFirstDate)
  }

  const onLastDayChange = (value: Date | undefined) => {
    const outOfOfficeLastDate = moment(value).tz(timezone).endOf('day').toDate()
    setFormState(state => ({...state, outOfOfficeLastDate}))
    validateLastDate(outOfOfficeLastDate)
  }

  const onUseOutOfOffice = (value: string) => {
    setFormState(state => ({...state, useOutOfOffice: value === 'true'}))
    // Restore original values if user disables useOutOfOffice prior to saving
    if (value === 'false') {
      setFormState(state => ({
        ...state,
        outOfOfficeFirstDate: originalFormState.outOfOfficeFirstDate,
        outOfOfficeLastDate: originalFormState.outOfOfficeLastDate,
        outOfOfficeSubject: originalFormState.outOfOfficeSubject,
        outOfOfficeMessage: originalFormState.outOfOfficeMessage,
      }))
      clearOutOfOfficeErrors()
    }
    // Populate today as default start/end date when user enables useOutOfOffice and no dates
    if (value === 'true' && !(formState.outOfOfficeFirstDate || formState.outOfOfficeLastDate)) {
      setFormState(state => ({
        ...state,
        outOfOfficeFirstDate: today.toDate(),
        outOfOfficeLastDate: today.endOf('day').toDate(),
      }))
      clearOutOfOfficeErrors()
    }
  }

  function onOutOfOfficeSubjectChange(value: string) {
    setFormState(state => ({...state, outOfOfficeSubject: value}))
    validateSubject(value)
  }

  const onOutOfOfficeMessageChange = (value: string) => {
    setFormState(state => ({...state, outOfOfficeMessage: value}))
    validateMessage(value)
  }

  const onUseSignature = (value: string) => {
    setFormState(state => ({...state, useSignature: value === 'true'}))
    // Restore original signature if user disables useSignature prior to saving
    if (value === 'false') {
      setFormState(state => ({
        ...state,
        signature: originalFormState.signature,
      }))
      setSignatureError(noError)
    }
  }

  const onSignatureChange = (value: string) => {
    setFormState(state => ({...state, signature: value}))
    validateSignature(value)
  }

  const firstDateInput = () => (
    <CanvasDateInput
      renderLabel={I18n.t('Start Date')}
      formatDate={dateFormatter}
      width="100%"
      display="block"
      timezone={timezone}
      messages={firstDateError}
      onSelectedDateChange={date => date && onFirstDayChange(date)}
      interaction={formState.useOutOfOffice ? 'enabled' : 'disabled'}
      selectedDate={formState.outOfOfficeFirstDate?.toISOString()}
      inputRef={setFirstDateRef}
    />
  )

  const lastDateInput = () => (
    <CanvasDateInput
      renderLabel={I18n.t('End Date')}
      formatDate={dateFormatter}
      width="100%"
      display="block"
      timezone={timezone}
      messages={lastDateError}
      onSelectedDateChange={date => date && onLastDayChange(date)}
      interaction={formState.useOutOfOffice ? 'enabled' : 'disabled'}
      selectedDate={formState.outOfOfficeLastDate?.toISOString()}
      inputRef={setLastDateRef}
    />
  )

  const onSaveInboxSettingsHandler = () => {
    let firstDateError = false
    let lastDateError = false
    let subjectError = false
    let messageError = false
    let signatureError = false

    if (inboxSignatureBlock) {
      signatureError = !validateSignatureOnSave()
    }
    if (inboxAutoResponse) {
      firstDateError = !validateFirstDateOnSave()
      lastDateError = !validateLastDateOnSave()
      subjectError = !validateSubjectOnSave()
      messageError = !validateMessageOnSave()
    }

    validateForm({
      firstDateError,
      lastDateError,
      subjectError,
      messageError,
      signatureError,
    })
      ? saveInboxSettings()
      : focusOnError()
  }

  const loadInboxSettingsSpinner = () => (
    <ModalSpinner
      label={I18n.t('Loading Inbox Settings')}
      message={I18n.t('Loading Inbox Settings')}
      onExited={() => {}}
    />
  )

  if (inboxSettingsLoading) return loadInboxSettingsSpinner()

  return (
    <Responsive
      match="media"
      query={{...responsiveQuerySizes({mobile: true, desktop: true})}}
      props={{
        mobile: {
          modalSize: 'fullscreen',
          dataTestId: 'inbox-settings-modal-mobile',
          modalBodyPadding: 'medium',
          isMobile: true,
        },
        desktop: {
          modalSize: 'medium',
          dataTestId: 'inbox-settings-modal-desktop',
          modalBodyPadding: 'large',
          isMobile: false,
        },
      }}
      render={responsiveProps => (
        <>
          <Modal
            open={isOpen}
            onDismiss={closeModal}
            onExited={() => setIsExited(true)}
            size={responsiveProps?.modalSize}
            label={I18n.t('Inbox Settings')}
            shouldCloseOnDocumentClick={false}
            data-testid={responsiveProps?.dataTestId}
          >
            <Modal.Body padding={responsiveProps?.modalBodyPadding || 'medium'}>
              <>
                {inboxAutoResponse && (
                  <>
                    <View as="div">
                      <Heading level="h3">
                        <Text weight="bold">{I18n.t('Out of Office')}</Text>
                      </Heading>
                    </View>
                    <View as="div" padding="x-small 0">
                      <Text size="small">{I18n.t('Send automatic replies to incoming mail.')}</Text>
                    </View>
                    <View as="div" padding="small 0 x-small 0">
                      <RadioInputGroup
                        name="response_toggle"
                        description={
                          <ScreenReaderContent>
                            {I18n.t('Out of Office Response')}
                          </ScreenReaderContent>
                        }
                        value={formState.useOutOfOffice ? 'true' : 'false'}
                        onChange={radioGroupInput =>
                          onUseOutOfOffice(radioGroupInput.currentTarget.value)
                        }
                      >
                        <RadioInput label={I18n.t('Response Off')} value="false" />
                        <RadioInput label={I18n.t('Response On')} value="true" />
                      </RadioInputGroup>
                    </View>
                    <View as="div">
                      {!responsiveProps?.isMobile ? (
                        <Flex
                          justifyItems="space-between"
                          alignItems="start"
                          padding="small 0 x-small 0"
                        >
                          <Flex.Item
                            padding="none small none none"
                            shouldShrink={true}
                            shouldGrow={true}
                          >
                            {firstDateInput()}
                          </Flex.Item>
                          <Flex.Item
                            padding="none none none small"
                            shouldShrink={true}
                            shouldGrow={true}
                          >
                            {lastDateInput()}
                          </Flex.Item>
                        </Flex>
                      ) : (
                        <>
                          <View as="div" padding="small 0 x-small 0">
                            {firstDateInput()}
                          </View>
                          <View as="div" padding="small 0 x-small 0">
                            {lastDateInput()}
                          </View>
                        </>
                      )}
                      <View as="div" padding="small 0 x-small 0">
                        <TextInput
                          renderLabel={I18n.t('Subject*')}
                          placeholder={I18n.t('Enter Subject')}
                          interaction={formState.useOutOfOffice ? 'enabled' : 'disabled'}
                          value={formState.outOfOfficeSubject || ''}
                          onChange={(_e, value) => onOutOfOfficeSubjectChange(value)}
                          inputRef={setSubjectRef}
                          messages={subjectError}
                          isRequired={formState.useOutOfOffice}
                          data-testid="out-of-office-subject-input"
                        />
                      </View>
                      <View as="div" padding="small 0 x-small 0">
                        <TextArea
                          label={I18n.t('Message')}
                          height="8rem"
                          maxHeight="10rem"
                          placeholder={I18n.t('Add Message')}
                          value={formState.outOfOfficeMessage || ''}
                          disabled={!formState.useOutOfOffice}
                          onChange={e => onOutOfOfficeMessageChange(e.currentTarget.value)}
                          textareaRef={setMessageRef}
                          messages={messageError}
                        />
                      </View>
                    </View>
                  </>
                )}
                {inboxSignatureBlock && (
                  <>
                    <View as="div" padding={inboxAutoResponse ? 'large 0 0' : '0 0 0'}>
                      <Heading level="h3">
                        <Text weight="bold">{I18n.t('Signature')}</Text>
                      </Heading>
                    </View>
                    <View as="div" padding="x-small 0">
                      <Text size="small">
                        {I18n.t('Signature will be added at the end of all messaging.')}
                      </Text>
                    </View>
                    <View as="div" padding="small 0 x-small 0">
                      <RadioInputGroup
                        name="signature_toggle"
                        description={
                          <ScreenReaderContent>{I18n.t('Signature On/Off')}</ScreenReaderContent>
                        }
                        value={formState.useSignature ? 'true' : 'false'}
                        onChange={radioGroupInput => {
                          onUseSignature(radioGroupInput.currentTarget.value)
                        }}
                      >
                        <RadioInput label={I18n.t('Signature Off')} value="false" />
                        <RadioInput label={I18n.t('Signature On')} value="true" />
                      </RadioInputGroup>
                    </View>
                    <View as="div" padding="small 0 x-small 0">
                      <TextArea
                        label={I18n.t('Signature*')}
                        height="8rem"
                        maxHeight="10rem"
                        placeholder={I18n.t('Add Signature')}
                        value={formState.signature}
                        disabled={!formState.useSignature}
                        onChange={e => onSignatureChange(e.currentTarget.value)}
                        textareaRef={setSignatureRef}
                        messages={signatureError}
                        required={formState.useSignature}
                        data-testid="inbox-signature-input"
                      />
                    </View>
                  </>
                )}
              </>
            </Modal.Body>
            <Modal.Footer>
              <Button
                type="button"
                color="secondary"
                margin="0 x-small 0 0"
                data-testid="cancel-button"
                onClick={() => closeModal()}
              >
                {I18n.t('Cancel')}
              </Button>
              <Button
                color={updateInboxSettingsLoading ? 'secondary' : 'primary'}
                margin="0 x-small 0 0"
                onClick={onSaveInboxSettingsHandler}
                interaction={updateInboxSettingsLoading ? 'disabled' : 'enabled'}
                data-testid="save-button"
              >
                {I18n.t('Save')}
              </Button>
            </Modal.Footer>
          </Modal>
          <ModalSpinner
            label={I18n.t('Saving Inbox Settings')}
            message={I18n.t('Saving Inbox Settings')}
            open={updateInboxSettingsLoading}
            onExited={() => {}}
          />
        </>
      )}
    />
  )
}

export default InboxSettingsModalContainer
