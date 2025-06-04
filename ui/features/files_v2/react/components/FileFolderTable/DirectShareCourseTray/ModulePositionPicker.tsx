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

import {SyntheticEvent, useCallback, useEffect, useState} from 'react'
import {doFetchApiWithAuthCheck, UnauthorizedError} from '../../../../utils/apiUtils'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('files_v2')

type ModulePositionPickerProps = {
  courseId: string
  moduleId: string
  onSelectPosition: (position: number | null) => void
}

type Position = {
  type: string
  label: string
}

type PositionType = 'first' | 'before' | 'after' | 'last'

type ModuleItem = {
  id: string
  title: string
}

// Copied from ui/shared/positions/positions.js
export const positions: {[key in PositionType]: Position} = {
  first: {
    type: 'absolute',
    get label() {
      return I18n.t('At the Top')
    },
  },
  before: {
    type: 'relative',
    get label() {
      return I18n.t('Before...')
    },
  },
  after: {
    type: 'relative',
    get label() {
      return I18n.t('After...')
    },
  },
  last: {
    type: 'absolute',
    get label() {
      return I18n.t('At the Bottom')
    },
  },
}

const ModulePositionPicker = ({
  courseId,
  moduleId,
  onSelectPosition,
}: ModulePositionPickerProps) => {
  const [moduleItems, setModuleItems] = useState<ModuleItem[]>([])
  const [position, setPosition] = useState<PositionType>('first')
  const [offset, setOffset] = useState<number>(0)
  const [siblingPosition, setSiblingPosition] = useState<number>(1)
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState<boolean>(false)

  useEffect(() => {
    setSiblingPosition(1)
    onSelectPosition(1 + offset)
    // eslint-disable-next-line react-compiler/react-compiler
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, moduleId])

  useEffect(() => {
    setIsLoading(true)
    doFetchApiWithAuthCheck<ModuleItem[]>({
      path: `/api/v1/courses/${courseId}/modules/${moduleId}/items`,
    })
      .then(response => response.json)
      .then((items?: ModuleItem[]) => {
        if (!items) throw new Error('Invalid response')
        setModuleItems(items)
        setError(null)
      })
      .catch(error => {
        if (error instanceof UnauthorizedError) {
          window.location.href = '/login'
          return
        }
        setError(I18n.t('Error retrieving module items'))
      })
      .finally(() => {
        setIsLoading(false)
      })
  }, [courseId, moduleId])

  const handleSetPosition = useCallback(
    (_e: SyntheticEvent, {value}: {value?: string | number | undefined}) => {
      const positionKey = value as PositionType
      setPosition(positionKey)
      switch (positionKey) {
        case 'first':
          setOffset(0)
          setSiblingPosition(1)
          onSelectPosition(1)
          break
        case 'last':
          setOffset(0)
          setSiblingPosition(1)
          onSelectPosition(null)
          break
        case 'after':
          setOffset(1)
          // + 1 for the offset that won't be set yet by the time we need it
          onSelectPosition(siblingPosition + 1)
          break
        case 'before':
          setOffset(0)
          onSelectPosition(siblingPosition)
          break
      }
    },
    [onSelectPosition, siblingPosition],
  )

  const handleSetSibling = useCallback(
    (_e: SyntheticEvent, {value}: {value?: string | number | undefined}) => {
      const pos = (value as number) + 1
      setSiblingPosition(pos)
      onSelectPosition(pos + offset)
    },
    [offset, onSelectPosition],
  )

  const renderSelectPlace = useCallback(() => {
    const messages = error ? [{text: error, type: 'newError'} as FormMessage] : []
    return (
      <SimpleSelect
        data-testid="select-position"
        renderLabel={I18n.t('Place')}
        value={position}
        onChange={handleSetPosition}
        messages={messages}
      >
        {Object.keys(positions).map(positionKey => {
          return (
            <SimpleSelect.Option id={positionKey} key={positionKey} value={positionKey}>
              {positions[positionKey as PositionType].label}
            </SimpleSelect.Option>
          )
        })}
      </SimpleSelect>
    )
  }, [error, handleSetPosition, position])

  const renderSelectSibling = useCallback(() => {
    if (isLoading)
      return <Spinner renderTitle={I18n.t('Loading additional items...')} size="x-small" />

    return (
      <SimpleSelect
        data-testid="select-sibling"
        renderLabel={I18n.t('Module Item')}
        onChange={handleSetSibling}
      >
        {moduleItems.map((item, index) => (
          <SimpleSelect.Option id={item.id} key={item.id} value={index}>
            {item.title}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    )
  }, [handleSetSibling, isLoading, moduleItems])

  return (
    <>
      <View as="div" margin="0 0 small 0">
        {renderSelectPlace()}
      </View>

      {positions[position]?.type === 'relative' && !error && (
        <View as="div" margin="0 0 small 0" textAlign="center">
          {renderSelectSibling()}
        </View>
      )}
    </>
  )
}

export default ModulePositionPicker
