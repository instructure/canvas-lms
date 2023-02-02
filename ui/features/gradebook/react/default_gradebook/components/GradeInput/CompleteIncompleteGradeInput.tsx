// @ts-nocheck
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

import React, {useState} from 'react'
import {bool, func, shape, string} from 'prop-types'
import {Select} from '@instructure/ui-select'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

function optionIdForGradeInfo(gradeInfo) {
  if (gradeInfo.excused) {
    return 'excused'
  }

  if (gradeInfo.grade == null) {
    return 'ungraded'
  }

  return gradeInfo.grade
}

function labelForGradeInfo(gradeInfo) {
  if (gradeInfo.excused) {
    return I18n.t('Excused')
  }

  return (
    {
      complete: I18n.t('Complete'),
      incomplete: I18n.t('Incomplete'),
    }[gradeInfo.grade] || I18n.t('Ungraded')
  )
}

export default function CompleteIncompleteGradeInput(props) {
  const {anonymizeStudents, isDisabled, gradeInfo, isBusy} = props

  const currentGradeValue = optionIdForGradeInfo(gradeInfo)

  const [highlightedItemId, setHighlightedItemId] = useState(currentGradeValue)
  const [isShowingOptions, setIsShowingOptions] = useState(false)

  function handleHighlightOption(_event, {id}) {
    setHighlightedItemId(id)
  }

  function gradeForOptionId(optionId) {
    return (
      {
        complete: 'complete',
        incomplete: 'incomplete',
      }[optionId] || null
    )
  }

  function handleSelectOption(_event, {id}) {
    setIsShowingOptions(false)
    if (!isDisabled && id !== gradeInfo.grade) {
      props.onChange(gradeForOptionId(id))
    }
  }

  const selectProps = {
    inputValue: anonymizeStudents ? '' : labelForGradeInfo(gradeInfo),
  }

  function isItemDisabled(optionId) {
    return isDisabled || (isBusy && gradeInfo.grade === gradeForOptionId(optionId))
  }

  let options

  if (gradeInfo.excused) {
    selectProps.interaction = isDisabled ? 'disabled' : 'readonly'

    options = [{id: 'excused', label: I18n.t('Excused')}]
  } else {
    selectProps.interaction = isDisabled ? 'disabled' : 'enabled'

    options = [
      {id: 'ungraded', label: I18n.t('Ungraded')},
      {id: 'complete', label: I18n.t('Complete')},
      {id: 'incomplete', label: I18n.t('Incomplete')},
    ]
  }

  return (
    <Select
      {...selectProps}
      id="grade-detail-tray--grade-input"
      isShowingOptions={isShowingOptions}
      onRequestHideOptions={() => setIsShowingOptions(false)}
      onRequestHighlightOption={handleHighlightOption}
      onRequestSelectOption={handleSelectOption}
      onRequestShowOptions={() => setIsShowingOptions(true)}
      renderLabel={() => I18n.t('Grade')}
    >
      {options.map(option => (
        <Select.Option
          id={option.id}
          isDisabled={isItemDisabled(option.id)}
          isHighlighted={option.id === highlightedItemId}
          isSelected={option.id === currentGradeValue}
          key={option.id}
        >
          {option.label}
        </Select.Option>
      ))}
    </Select>
  )
}

CompleteIncompleteGradeInput.propTypes = {
  anonymizeStudents: bool.isRequired,
  gradeInfo: shape({
    excused: bool.isRequired,
    grade: string,
    valid: bool.isRequired,
  }).isRequired,
  isBusy: bool.isRequired,
  isDisabled: bool.isRequired,
  onChange: func.isRequired,
}
