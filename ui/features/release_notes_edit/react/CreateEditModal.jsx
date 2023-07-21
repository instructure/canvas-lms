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
import PropTypes from 'prop-types'
import React, {useReducer, useEffect} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import DateTimeInput from '@canvas/datetime/react/components/DateTimeInput'
import CanvasMultiSelect from '@canvas/multi-select'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ToggleGroup} from '@instructure/ui-toggle-details'

import {roles} from './util'

const I18n = useI18nScope('release_notes')

const formatLanguage = new Intl.DisplayNames(['en'], {type: 'language'})

function createDefaultState() {
  return {
    target_roles: ['user'],
    langs: {},
    show_ats: {},
  }
}

function editReducer(state, action) {
  if (action.action === 'RESET') {
    if (action.payload) {
      return action.payload
    } else {
      return createDefaultState()
    }
  } else if (action.action === 'SET_ATTR') {
    return {...state, [action.payload.key]: action.payload.value}
  } else if (action.action === 'SET_RELEASE_DATE') {
    return {
      ...state,
      show_ats: {...state.show_ats, [action.payload.env]: action.payload.value},
    }
  } else if (action.action === 'SET_LANG_ATTR') {
    const lang = action.payload.lang
    return {
      ...state,
      langs: {
        ...state.langs,
        [lang]: {...state.langs[lang], [action.payload.key]: action.payload.value},
      },
    }
  }
  return state
}

function isFormSubmittable(state) {
  return state.langs.en && state.langs.en.title && state.langs.en.description
}

function CreateEditModal({open, onClose, onSubmit, currentNote, envs, langs}) {
  const [state, reducer] = useReducer(editReducer, createDefaultState())

  useEffect(() => {
    reducer({action: 'RESET', payload: currentNote})
  }, [currentNote])

  const label = currentNote ? I18n.t('Edit Release Note') : I18n.t('New Release Note')

  function submit(payload) {
    onSubmit(payload)
    reducer({action: 'RESET', payload: null})
  }

  return (
    <Modal
      as="form"
      open={open}
      onDismiss={onClose}
      onSubmit={e => {
        e.preventDefault()
        submit(state)
      }}
      size="fullscreen"
      label={label}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{label}</Heading>
      </Modal.Header>
      <Modal.Body>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Dates')}</ScreenReaderContent>}
          layout="columns"
          startAt="small"
          vAlign="top"
          width="auto"
        >
          {envs.map(env => {
            return (
              <DateTimeInput
                key={env}
                description={I18n.t('Release Date for: ') + env[0].toUpperCase() + env.slice(1)}
                onChange={newValue =>
                  reducer({action: 'SET_RELEASE_DATE', payload: {env, value: newValue}})
                }
                value={state.show_ats[env]}
                data-testid={`show_at_input-${env}`}
              />
            )
          })}
        </FormFieldGroup>
        <CanvasMultiSelect
          label={I18n.t('Available to')}
          assistiveText={I18n.t(
            'Select target groups. Type or use arrow keys to navigate. Multiple selections are allowed.'
          )}
          selectedOptionIds={state.target_roles}
          onChange={newValue =>
            reducer({action: 'SET_ATTR', payload: {key: 'target_roles', value: newValue}})
          }
        >
          {roles.map(role => {
            return (
              <CanvasMultiSelect.Option id={role.id} value={role.id} key={role.id}>
                {role.label}
              </CanvasMultiSelect.Option>
            )
          })}
        </CanvasMultiSelect>
        {langs.map(lang => {
          const isRequired = lang === 'en'
          return (
            <ToggleGroup
              defaultExpanded={isRequired}
              summary={formatLanguage.of(lang)}
              toggleLabel={I18n.t('Expand/collapse %{lang}', {lang: formatLanguage.of(lang)})}
              size="small"
              key={lang}
              transition={false}
            >
              <>
                <TextInput
                  renderLabel={I18n.t('Title')}
                  value={state.langs[lang]?.title || ''}
                  onChange={(_e, v) =>
                    reducer({action: 'SET_LANG_ATTR', payload: {lang, key: 'title', value: v}})
                  }
                  isRequired={isRequired}
                  data-testid={`title_input-${lang}`}
                />
                <TextArea
                  label={I18n.t('Description')}
                  value={state.langs[lang]?.description || ''}
                  onChange={e =>
                    reducer({
                      action: 'SET_LANG_ATTR',
                      payload: {lang, key: 'description', value: e.target.value},
                    })
                  }
                  required={isRequired}
                  data-testid={`description_input-${lang}`}
                />
                <TextInput
                  renderLabel={I18n.t('Link URL')}
                  value={state.langs[lang]?.url || ''}
                  onChange={(_e, v) =>
                    reducer({action: 'SET_LANG_ATTR', payload: {lang, key: 'url', value: v}})
                  }
                  type="url"
                  data-testid={`url_input-${lang}`}
                />
              </>
            </ToggleGroup>
          )
        })}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button
          disabled={!isFormSubmittable(state)}
          onClick={() => submit({...state, published: true})}
          data-testid="submit_button"
        >
          {I18n.t('Save and Publish')}
        </Button>
        <Button color="primary" type="submit" disabled={!isFormSubmittable(state)}>
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

CreateEditModal.propTypes = {
  open: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  currentNote: PropTypes.object,
  envs: PropTypes.array.isRequired,
  langs: PropTypes.array.isRequired,
}

export default CreateEditModal
