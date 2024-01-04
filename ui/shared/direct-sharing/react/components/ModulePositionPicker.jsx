/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import React, {useState, useEffect} from 'react'
import {func, string} from 'prop-types'

import {useCourseModuleItemApi} from '../effects/useModuleCourseSearchApi'
import SelectPosition from '@canvas/select-position'
import {positions} from '@canvas/positions'

const I18n = useI18nScope('module_position_picker')

ModulePositionPicker.propTypes = {
  courseId: string.isRequired,
  moduleId: string.isRequired,
  setModuleItemPosition: func,
}

ModulePositionPicker.defaultProps = {
  setModuleItemPosition: () => {},
}

export default function ModulePositionPicker({courseId, moduleId, setModuleItemPosition}) {
  const [moduleItems, setModuleItems] = useState([])
  const [position, setPosition] = useState(null)
  const [offset, setOffset] = useState(0)
  const [siblingPosition, setSiblingPosition] = useState(1)
  const [error, setError] = useState(null)
  const [isLoading, setIsLoading] = useState(false)

  useEffect(() => {
    setSiblingPosition(1)
    setModuleItemPosition(1 + offset)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, moduleId])

  const params = {contextId: courseId, moduleId}
  useCourseModuleItemApi({
    success: setModuleItems,
    error: setError,
    loading: setIsLoading,
    fetchAllPages: true,
    params,
  })

  if (error !== null) throw error

  function handleSetPosition(e) {
    const pos = e.target.value
    setPosition(positions[pos])
    switch (pos) {
      case 'first':
        setOffset(0)
        setSiblingPosition(1)
        setModuleItemPosition(1)
        break
      case 'last':
        setOffset(0)
        setSiblingPosition(1)
        setModuleItemPosition(null)
        break
      case 'after':
        setOffset(1)
        // + 1 for the offset that won't be set yet by the time we need it
        setModuleItemPosition(siblingPosition + 1)
        break
      case 'before':
        setOffset(0)
        setModuleItemPosition(siblingPosition)
        break
    }
  }

  function handleSetSibling(e) {
    const pos = parseInt(e.target.value, 10) + 1
    setSiblingPosition(pos)
    setModuleItemPosition(pos + offset)
  }

  return (
    <SelectPosition
      items={[]}
      siblings={
        isLoading
          ? moduleItems.concat({
              title: I18n.t('Loading additional items...'),
              id: '0',
              groupId: '0',
            })
          : moduleItems
      }
      selectedPosition={position}
      selectPosition={handleSetPosition}
      selectSibling={handleSetSibling}
    />
  )
}
