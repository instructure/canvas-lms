/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {TextInput} from '@instructure/ui-text-input'
import React, {useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Portal} from '@instructure/ui-portal'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('eportfolio')

interface PageFormProps {
  readonly pageName: string
  readonly contentBtnNode: HTMLElement
  readonly sideBtnNode: HTMLElement
  readonly onPreview: () => void
  readonly onSave: () => void
  readonly onCancel: () => void
  readonly onKeepEditing: () => void
  readonly setHidden: (hidden: string) => void
}

export default function PageNameContainer(props: PageFormProps) {
  const [isPreview, setIsPreview] = useState(false)
  const [pageName, setPageName] = useState(props.pageName)
  const [errors, setErorrs] = useState('')

  const nameRef = useRef<TextInput>(null)

  const handlePreview = () => {
    setIsPreview(true)
    props.onPreview()
  }
  const handleKeepEditing = () => {
    setIsPreview(false)
    props.onKeepEditing()
  }
  const handleSave = () => {
    if (pageName === '') {
      if (nameRef.current) {
        nameRef.current.focus()
      }
      setErorrs(I18n.t('Page name is required'))
    } else {
      props.setHidden(pageName)
      props.onSave()
    }
  }

  const handleChange = (value: string) => {
    setPageName(value)
    if (value === '') {
      setErorrs(I18n.t('Page name is required'))
    } else {
      setErorrs('')
    }
  }

  return (
    <>
      {isPreview ? null : (
        <TextInput
          data-testid="page-name-input"
          ref={nameRef}
          value={pageName}
          onChange={(_e, val) => handleChange(val)}
          isRequired={true}
          renderLabel={I18n.t('Page name')}
          messages={errors === '' ? [] : [{type: 'newError', text: errors}]}
        />
      )}
      <Portal open={true} mountNode={props.contentBtnNode}>
        <PageFormButtons
          isPreview={isPreview}
          onPreview={handlePreview}
          onKeepEditing={handleKeepEditing}
          onCancel={props.onCancel}
          onSave={handleSave}
        />
      </Portal>
      <Portal open={true} mountNode={props.sideBtnNode}>
        <PageFormButtons
          isPreview={isPreview}
          onPreview={handlePreview}
          onKeepEditing={handleKeepEditing}
          onCancel={props.onCancel}
          onSave={handleSave}
        />
      </Portal>
    </>
  )
}

interface PageButtonProps {
  readonly isPreview: boolean
  readonly onPreview: () => void
  readonly onSave: () => void
  readonly onCancel: () => void
  readonly onKeepEditing: () => void
}

function PageFormButtons(props: PageButtonProps) {
  return (
    <Flex gap="x-small" margin="x-small 0">
      <Button onClick={props.onCancel}>{I18n.t('Cancel')}</Button>
      {props.isPreview ? (
        <Button onClick={props.onKeepEditing}>{I18n.t('Keep Editing')}</Button>
      ) : (
        <Button onClick={props.onPreview}>{I18n.t('Preview')}</Button>
      )}
      <Button color="primary" data-testid="save-page" onClick={props.onSave}>
        {I18n.t('Save')}
      </Button>
    </Flex>
  )
}
