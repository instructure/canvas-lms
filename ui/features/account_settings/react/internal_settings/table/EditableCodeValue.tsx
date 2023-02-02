// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {InPlaceEdit} from '@instructure/ui-editable'
import React, {ChangeEvent, LegacyRef, ReactNode, useEffect, useState} from 'react'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ButtonProps, IconButton} from '@instructure/ui-buttons'
import {IconEditLine} from '@instructure/ui-icons'

const I18n = useI18nScope('internal-settings')

export type EditableCodeValueProps = {
  value: string
  name?: string
  secret?: boolean
  readonly?: boolean
  screenReaderLabel?: string
  placeholder?: ReactNode
  onValueChange: (newValue: string) => void
}

export const EditableCodeValue = (props: EditableCodeValueProps) => {
  const [mode, setMode] = useState<'view' | 'edit'>('view')
  const [editorValue, setEditorValue] = useState(props.value)

  useEffect(() => {
    setEditorValue(props.value)
  }, [props.value])

  const handleChange = (event: ChangeEvent<HTMLInputElement>) => {
    setEditorValue(event.target?.value)
  }

  const renderEditButton = ({
    isVisible,
    readOnly,
    ...buttonProps
  }: ButtonProps & {
    isVisible: boolean
    readOnly: boolean
  }) => {
    if (readOnly) return null

    return (
      <IconButton
        size="small"
        screenReaderLabel={
          props.screenReaderLabel ||
          (props.name
            ? I18n.t(`Edit value for "%{name}"`, {name: props.name})
            : I18n.t('Edit value'))
        }
        withBackground={false}
        withBorder={false}
        {...buttonProps}
      >
        {isVisible ? IconEditLine : null}
      </IconButton>
    )
  }

  const renderView = () =>
    props.placeholder || (
      <Text>
        <code style={{wordBreak: 'break-word'}}>{props.secret ? '*'.repeat(24) : props.value}</code>
      </Text>
    )

  const renderEdit = ({
    onBlur,
    editorRef,
  }: {
    onBlur: () => void
    editorRef: LegacyRef<HTMLInputElement>
  }) => (
    <Text
      as="input"
      name={(props.name ? `${props.name} ` : '') + 'value'}
      type={props.secret ? 'password' : 'text'}
      onChange={handleChange}
      onBlur={onBlur}
      autocomplete="off"
      value={editorValue}
      elementRef={editorRef}
    />
  )

  return (
    <div>
      <InPlaceEdit
        renderViewer={renderView}
        renderEditor={renderEdit}
        renderEditButton={renderEditButton}
        readOnly={props.readonly}
        mode={mode}
        onChangeMode={setMode}
        value={editorValue}
        inline={false}
        onChange={props.onValueChange}
      />
    </div>
  )
}
