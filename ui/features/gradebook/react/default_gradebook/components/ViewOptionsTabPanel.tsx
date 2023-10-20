// @ts-nocheck
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

import React from 'react'

import {bool, func, objectOf, shape, string} from 'prop-types'
import {Checkbox} from '@instructure/ui-checkbox'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {SimpleSelect} from '@instructure/ui-simple-select'
import type {SimpleSelectProps} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import StatusColorPanel from './StatusColorPanel'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

function buildAssignmentSortOptions(includeModules) {
  const options = [
    {criterion: 'default', direction: 'ascending', label: I18n.t('Default Order')},
    {criterion: 'name', direction: 'ascending', label: I18n.t('Assignment Name - A-Z')},
    {criterion: 'name', direction: 'descending', label: I18n.t('Assignment Name - Z-A')},
    {criterion: 'due_date', direction: 'ascending', label: I18n.t('Due Date - Oldest to Newest')},
    {criterion: 'due_date', direction: 'descending', label: I18n.t('Due Date - Newest to Oldest')},
    {criterion: 'points', direction: 'ascending', label: I18n.t('Points - Lowest to Highest')},
    {criterion: 'points', direction: 'descending', label: I18n.t('Points - Highest to Lowest')},
  ]

  if (includeModules) {
    options.push(
      {
        criterion: 'module_position',
        direction: 'ascending',
        label: I18n.t('Module - First to Last'),
      },
      {
        criterion: 'module_position',
        direction: 'descending',
        label: I18n.t('Module - Last to First'),
      }
    )
  }

  return options.map(option => ({
    ...option,
    value: `${option.criterion}-${option.direction}`,
  }))
}

function renderCheckbox(setting, label, key) {
  return (
    <Checkbox
      checked={setting.checked}
      onChange={event => setting.onChange(event.target.checked)}
      id={`view-options-show-${key}`}
      label={label}
      value={key}
    />
  )
}

export default function ViewOptionsTabPanel({
  columnSort,
  finalGradeOverrideEnabled,
  hideAssignmentGroupTotals,
  hideTotal,
  showNotes,
  showUnpublishedAssignments,
  showSeparateFirstLastNames,
  statusColors,
  viewUngradedAsZero,
}) {
  const sortOptions = buildAssignmentSortOptions(columnSort.modulesEnabled)
  const selectedSortKey =
    sortOptions.find(
      option =>
        option.criterion === columnSort.currentValue.criterion &&
        option.direction === columnSort.currentValue.direction
    ) || sortOptions[0]

  const handleColumnSortSelected: SimpleSelectProps['onChange'] = (e, {value}) => {
    const matchingSortOption = sortOptions.find(option => option.value === value)

    if (typeof matchingSortOption !== 'undefined') {
      const {criterion, direction} = matchingSortOption
      columnSort.onChange({criterion, direction})
    }
  }

  return (
    <div id="ViewOptionsTabPanel__Container">
      <View as="div" margin="small">
        <SimpleSelect
          data-testid="arrange_by_dropdown"
          renderLabel={I18n.t('Arrange By')}
          onChange={handleColumnSortSelected}
          value={selectedSortKey.value}
        >
          {sortOptions.map(option => (
            <SimpleSelect.Option
              id={`sort-${option.value}`}
              key={option.value}
              value={option.value}
            >
              {option.label}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>

        <View as="div" margin="large 0 large">
          <FormFieldGroup description={I18n.t('Show')} layout="stacked" rowSpacing="small">
            {renderCheckbox(showNotes, I18n.t('Notes'), 'showNotes')}
            {renderCheckbox(
              showUnpublishedAssignments,
              I18n.t('Unpublished Assignments'),
              'showUnpublishedAssignments'
            )}
            {showSeparateFirstLastNames.allowed &&
              renderCheckbox(
                showSeparateFirstLastNames,
                I18n.t('Split Student Names'),
                'showSeparateFirstLastNames'
              )}
            {renderCheckbox(
              hideAssignmentGroupTotals,
              I18n.t('Hide Assignment Group Totals'),
              'hideAssignmentGroupTotals'
            )}
            {renderCheckbox(
              hideTotal,
              finalGradeOverrideEnabled
                ? I18n.t('Hide Total and Override Columns')
                : I18n.t('Hide Total Column'),
              'hideTotal'
            )}
            {viewUngradedAsZero.allowed &&
              renderCheckbox(
                viewUngradedAsZero,
                I18n.t('View ungraded as 0'),
                'viewUngradedAsZero'
              )}
          </FormFieldGroup>
        </View>

        <FormFieldGroup description={I18n.t('Status Color')}>
          <StatusColorPanel
            colors={statusColors.currentValues}
            onColorsUpdated={statusColors.onChange}
          />
        </FormFieldGroup>
      </View>
    </div>
  )
}

ViewOptionsTabPanel.propTypes = {
  columnSort: shape({
    currentValue: shape({
      criterion: string.isRequired,
      direction: string.isRequired,
    }),
    modulesEnabled: bool.isRequired,
    onChange: func.isRequired,
  }).isRequired,
  finalGradeOverrideEnabled: bool.isRequired,
  hideAssignmentGroupTotals: shape({
    checked: bool.isRequired,
    onChange: func.isRequired,
  }).isRequired,
  hideTotal: shape({
    checked: bool.isRequired,
    onChange: func.isRequired,
  }).isRequired,
  showNotes: shape({
    checked: bool.isRequired,
    onChange: func.isRequired,
  }).isRequired,
  showUnpublishedAssignments: shape({
    checked: bool.isRequired,
    onChange: func.isRequired,
  }).isRequired,
  showSeparateFirstLastNames: shape({
    allowed: bool.isRequired,
    checked: bool.isRequired,
    onChange: func.isRequired,
  }).isRequired,
  statusColors: shape({
    currentValues: objectOf(string).isRequired,
    onChange: func.isRequired,
  }).isRequired,
  viewUngradedAsZero: shape({
    allowed: bool.isRequired,
    checked: bool.isRequired,
    onChange: func.isRequired,
  }).isRequired,
}
