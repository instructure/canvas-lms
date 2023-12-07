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

import React, {useCallback, useEffect, useState} from 'react'
import {Editable} from '@instructure/ui-editable'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

type EditorMode = 'view' | 'edit'

type HeadingEditorProps = {
  value: string
  onChange: (value: string) => void
}

const HeadingEditor = ({value, onChange}: HeadingEditorProps) => {
  const [editMode, setEditMode] = useState<EditorMode>('view')
  const [currValue, setCurrValue] = useState(value)
  const [isHovering, setIsHovering] = useState(false)

  useEffect(() => {
    setCurrValue(value)
  }, [value])

  const handleModeChange = useCallback((newMode: string) => {
    setEditMode(newMode as EditorMode)
  }, [])

  const handleValueChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    setCurrValue(event.target.value)
  }, [])

  const handleKey = useCallback((event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter') {
      event.preventDefault()
      setEditMode('view')
    }
  }, [])

  const renderButton = useCallback(({isVisible, onClick, onFocus, onBlur, buttonRef}) => {
    // To correctly handle focus, always return the Button, but
    // only visible if isVisible (if you want the UI to work in the standard way)
    setIsHovering(isVisible)
    return (
      <span style={{opacity: isVisible ? 1 : 0}}>
        <View as="div" background="secondary" padding="0 0 0 x-small">
          <IconButton
            screenReaderLabel="Edit"
            size="large"
            onClick={onClick}
            onFocus={onFocus}
            onBlur={onBlur}
            elementRef={buttonRef}
            withBackground={false}
            withBorder={false}
          >
            <IconEditLine />
          </IconButton>
        </View>
      </span>
    )
  }, [])

  const renderViewer = useCallback(() => {
    return (
      <View as="div" background={isHovering ? 'secondary' : 'transparent'}>
        <Heading level="h1" themeOverride={{h1FontWeight: 700}}>
          {currValue}
        </Heading>
      </View>
    )
  }, [currValue, isHovering])

  const renderEditor = useCallback(
    ({onBlur, editorRef}) => {
      return (
        <input
          style={{fontSize: '2.375rem', backgroundColor: '#f5f5f5', width: '100%', fontWeight: 700}}
          ref={editorRef}
          onBlur={onBlur}
          value={currValue}
          onChange={handleValueChange}
          onKeyDown={handleKey}
        />
      )
    },
    [currValue, handleKey, handleValueChange]
  )

  const renderMe = useCallback(
    ({mode, getContainerProps, getEditorProps, getEditButtonProps}) => {
      return (
        <Flex {...getContainerProps()}>
          <Flex.Item shouldGrow={true}>
            {mode === 'view' ? renderViewer() : renderEditor(getEditorProps())}
          </Flex.Item>
          {renderButton(getEditButtonProps())}
        </Flex>
      )
    },
    [renderButton, renderEditor, renderViewer]
  )

  return (
    <Editable
      mode={editMode}
      onChangeMode={handleModeChange}
      onChange={onChange}
      render={renderMe}
      value={currValue}
      readOnly={false}
    />
  )
}

export default HeadingEditor
