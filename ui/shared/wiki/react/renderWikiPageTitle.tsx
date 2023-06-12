/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useEffect, useRef, useState} from 'react'
import ReactDOM from 'react-dom'
import {TextInput, TextInputProps} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import type JQuery from 'jquery'
import type WikiPageEditView from '../backbone/views/WikiPageEditView'

const I18n = useI18nScope('pages_edit_title')

interface ComponentProps {
  canEdit: boolean
  isContentLocked: boolean
  viewElement: JQuery<HTMLFormElement> & WikiPageEditView
  validationCallback: (data: Record<string, unknown>) => ValidationResult
}

interface InputError {
  text: string
  type: string
}

interface FormDataError {
  message: string
  type: string
}

interface ValidationResult {
  [k: string]: FormDataError[]
}

export type Props = TextInputProps & ComponentProps

const EditableContent = (props: Props) => {
  const [errors, setErrors] = useState<InputError[]>([])
  const inputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    const handleSubmit = (evt?: JQuery.Event) => {
      evt?.stopPropagation()
      const data = props.viewElement.getFormData()
      const dataErrors = props.validationCallback(data)
      const titleErrors = dataErrors?.title || []
      if (titleErrors.length > 0) {
        const parsedErrors = titleErrors.map((error: FormDataError) => ({
          text: error.message,
          type: 'error',
        }))
        setErrors(parsedErrors)
        return false
      }
    }

    if (inputRef.current !== null) {
      // The generated input element must have the name "title" to be
      // included in the current submission process
      inputRef.current.name = 'title'
    }

    props.viewElement.on('submit', handleSubmit)
    return () => {
      props.viewElement.off('submit', handleSubmit)
    }
  }, [props])

  return props.isContentLocked ? (
    <>
      <Heading data-testid="wikipage-locked-title" level="h1">
        {props.defaultValue}
      </Heading>
      <input name="title" type="hidden" value={props.defaultValue} />
    </>
  ) : (
    <View as="div" maxWidth="356px">
      <TextInput
        data-testid="wikipage-title-input"
        inputRef={ref => (inputRef.current = ref)}
        messages={errors}
        renderLabel={() => (
          <Text size="small" weight="normal">
            {I18n.t('Page Title')}
          </Text>
        )}
        {...props}
      />
    </View>
  )
}

const renderWikiPageTitle = (props: Props) => {
  const readOnlyContent = (
    <Heading data-testid="wikipage-readonly-title" level="h2">
      {props.defaultValue}
    </Heading>
  )

  const titleComponent = props.canEdit ? <EditableContent {...props} /> : readOnlyContent
  const wikiPageTitleContainer = document.getElementById('edit_wikipage_title_container')
  if (wikiPageTitleContainer) {
    ReactDOM.render(titleComponent, wikiPageTitleContainer)
  }

  return titleComponent
}

export default renderWikiPageTitle
