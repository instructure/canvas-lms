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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useReducer, useEffect, useState, useRef, createContext, useContext} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import CanvasMultiSelect from '@canvas/multi-select'
import {FormFieldGroup, type FormMessage} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {pick, capitalize} from 'lodash'
import {reducer, Actions as A, type ReducerParams} from './createEditModalReducer'
import {roles, createDefaultState} from './util'
import {ReleaseNoteEditing, type ReleaseNote} from './types'

const I18n = createI18nScope('release_notes')

const locales = ENV?.LOCALES || navigator.languages || ['en-US']
const formatLanguage = new Intl.DisplayNames(locales, {type: 'language'})

const Context = createContext<ReducerParams>({state: createDefaultState(null), dispatch: () => {}})

// Given an array of elements, sort them by their vertical position
function sortByVerticalPosition(elts: HTMLElement[]): HTMLElement[] {
  return elts
    .filter(elt => typeof elt !== 'undefined')
    .map(elt => ({elt, rect: elt.getBoundingClientRect()}))
    .sort((a, b) => a.rect.top - b.rect.top)
    .map(item => item.elt)
}

function SelectDateForEnv({env}: {env: string}): JSX.Element {
  const [messages, setMessages] = useState<FormMessage[]>([])
  const {state, dispatch} = useContext(Context)
  const value = state.show_ats[env]
  const {isSubmitting} = state
  const el = useRef<HTMLElement | null>(null)
  const key = `date-${env}`

  function validate(v: string | undefined, display: boolean) {
    const dateMessages: FormMessage[] = []
    if (typeof v === 'undefined')
      dateMessages.push({text: I18n.t('Release date is required'), type: 'newError'})
    else {
      const selDate = new Date(v)
      const curDate = new Date()
      if (selDate < curDate)
        dateMessages.push({text: I18n.t('Release date must be in the future'), type: 'newError'})
    }
    if (display || isSubmitting) setMessages(dateMessages)
    if (dateMessages.length === 0) dispatch({action: A.CLEAR_ERROR_ELEMENT, payload: {key}})
    else dispatch({action: A.SET_ERROR_ELEMENT, payload: {key, value: el.current}})
  }

  function handleChange(_e: unknown, isoValue?: string) {
    validate(isoValue, true)
    dispatch({action: A.SET_RELEASE_DATE, payload: {env, value: isoValue}})
  }

  useEffect(() => validate(value, isSubmitting), [isSubmitting, value])

  return (
    <DateTimeInput
      dateInputRef={ref => (el.current = ref)}
      layout="columns"
      dateRenderLabel={I18n.t('Date')}
      timeRenderLabel={I18n.t('Time')}
      prevMonthLabel={I18n.t('Previous month')}
      nextMonthLabel={I18n.t('Next month')}
      invalidDateTimeMessage={I18n.t('Enter a valid future date and time')}
      description={I18n.t('Release Date for %{environment}', {environment: capitalize(env)})}
      onChange={handleChange}
      onBlur={() => validate(value, true)}
      value={value}
      isRequired={true}
      messages={messages}
      data-testid={`show_at_input-${env}`}
    />
  )
}

function SelectTitleForLang({lang}: {lang: string}): JSX.Element {
  const [messages, setMessages] = useState<FormMessage[]>([])
  const {state, dispatch} = useContext(Context)
  const value = state.langs[lang]?.title || ''
  const {isSubmitting} = state
  const el = useRef<HTMLElement | null>(null)
  const key = `title-${lang}`
  const isRequired = lang === 'en'

  function validate(v: string, display: boolean) {
    const textMessages: FormMessage[] = []
    if (isRequired && v.length === 0)
      textMessages.push({text: I18n.t('Required for English locale'), type: 'newError'})
    if (display || isSubmitting) setMessages(textMessages)
    if (textMessages.length === 0) dispatch({action: A.CLEAR_ERROR_ELEMENT, payload: {key}})
    else dispatch({action: A.SET_ERROR_ELEMENT, payload: {key, value: el.current}})
  }

  function handleChange(_e: React.ChangeEvent<HTMLInputElement>, v: string) {
    const value = v.trimStart()
    validate(value, true)
    dispatch({action: A.SET_LANG_ATTR, payload: {lang, key: 'title', value}})
  }

  useEffect(() => validate(value, isSubmitting), [isSubmitting, value])

  return (
    <TextInput
      inputRef={ref => (el.current = ref)}
      renderLabel={I18n.t('Title')}
      value={value}
      onChange={handleChange}
      isRequired={isRequired}
      onBlur={() => validate(value, true)}
      messages={messages}
      data-testid={`title_input-${lang}`}
    />
  )
}

function SelectDescForLang({lang}: {lang: string}): JSX.Element {
  const [messages, setMessages] = useState<FormMessage[]>([])
  const {state, dispatch} = useContext(Context)
  const value = state.langs[lang]?.description || ''
  const {isSubmitting} = state
  const el = useRef<HTMLElement | null>(null)
  const key = `desc-${lang}`
  const isRequired = lang === 'en'

  function validate(v: string, display: boolean) {
    const textMessages: FormMessage[] = []
    if (isRequired && v.length === 0)
      textMessages.push({text: I18n.t('Required for English locale'), type: 'newError'})
    if (display || isSubmitting) setMessages(textMessages)
    if (textMessages.length === 0) dispatch({action: A.CLEAR_ERROR_ELEMENT, payload: {key}})
    else dispatch({action: A.SET_ERROR_ELEMENT, payload: {key, value: el.current}})
  }

  function handleChange(e: React.ChangeEvent<HTMLTextAreaElement>) {
    const value = e.target.value.trimStart()
    validate(value, true)
    dispatch({action: A.SET_LANG_ATTR, payload: {lang, key: 'description', value}})
  }

  useEffect(() => validate(value, isSubmitting), [isSubmitting, value])

  return (
    <TextArea
      textareaRef={ref => (el.current = ref)}
      label={I18n.t('Description')}
      value={value}
      onChange={handleChange}
      required={isRequired}
      onBlur={() => validate(value, true)}
      messages={messages}
      data-testid={`description_input-${lang}`}
    />
  )
}

export interface CreateEditModalProps {
  open: boolean
  onClose: () => void
  onSubmit: (payload: ReleaseNote) => void
  currentNote: ReleaseNote | null
  envs: string[]
  langs: string[]
}

function CreateEditModal({
  open,
  onClose,
  onSubmit,
  currentNote,
  envs,
  langs,
}: CreateEditModalProps): JSX.Element {
  const [state, dispatch] = useReducer(reducer, createDefaultState(null))
  const isPublished = Boolean(currentNote?.published)
  const errorElements = sortByVerticalPosition(Object.values(state.elementsWithErrors))

  useEffect(() => {
    dispatch({action: A.RESET, payload: currentNote})
  }, [currentNote])

  const label = currentNote ? I18n.t('Edit Release Note') : I18n.t('New Release Note')

  function submit(payload: ReleaseNoteEditing) {
    dispatch({action: A.SET_SUBMIT})
    if (errorElements.length > 0) {
      errorElements[0].focus()
      return
    }
    onSubmit(pick(payload, ['id', 'target_roles', 'langs', 'show_ats', 'published']))
    dispatch({action: A.RESET})
  }

  function handleClose() {
    onClose()
    // If modal is closed without saving, reset the state to reflect
    // the current note, so that the next time the modal is opened
    // any changes made get discarded.
    dispatch({action: A.RESET, payload: currentNote})
  }

  return (
    <Modal open={open} onDismiss={handleClose} size="medium" label={label}>
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{label}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Context.Provider value={{state, dispatch}}>
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Dates')}</ScreenReaderContent>}
            layout="columns"
            startAt="small"
            vAlign="top"
            width="auto"
          >
            {envs.map(env => (
              <SelectDateForEnv key={env} env={env} />
            ))}
          </FormFieldGroup>

          <CanvasMultiSelect
            label={I18n.t('Available to')}
            assistiveText={I18n.t(
              'Select target groups. Type or use arrow keys to navigate. Multiple selections are allowed.',
            )}
            selectedOptionIds={state.target_roles}
            onChange={newValue =>
              dispatch({action: A.SET_TARGET_ROLES, payload: {value: newValue}})
            }
          >
            {roles.map(role => {
              return (
                <CanvasMultiSelect.Option label="" id={role.id} value={role.id} key={role.id}>
                  {role.label}
                </CanvasMultiSelect.Option>
              )
            })}
          </CanvasMultiSelect>
          {langs.map(lang => {
            return (
              <ToggleGroup
                defaultExpanded={lang === 'en'}
                summary={formatLanguage.of(lang)}
                toggleLabel={I18n.t('Expand/collapse %{lang}', {lang: formatLanguage.of(lang)})}
                size="small"
                key={lang}
                transition={false}
              >
                <>
                  <SelectTitleForLang lang={lang} />
                  <SelectDescForLang lang={lang} />
                  <TextInput
                    renderLabel={I18n.t('Link URL')}
                    value={state.langs[lang]?.url || ''}
                    onChange={(_e, v) =>
                      dispatch({action: A.SET_LANG_ATTR, payload: {lang, key: 'url', value: v}})
                    }
                    type="url"
                    data-testid={`url_input-${lang}`}
                  />
                </>
              </ToggleGroup>
            )
          })}
        </Context.Provider>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={handleClose} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button
          color={isPublished ? 'primary' : undefined}
          onClick={() => submit({...state, published: true})}
          data-testid="save_published_button"
        >
          {isPublished ? I18n.t('Save') : I18n.t('Save and Publish')}
        </Button>
        <Button
          color={isPublished ? undefined : 'primary'}
          onClick={() => submit({...state, published: false})}
          data-testid="save_unpublished_button"
        >
          {isPublished ? I18n.t('Unpublish and Save') : I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default CreateEditModal
