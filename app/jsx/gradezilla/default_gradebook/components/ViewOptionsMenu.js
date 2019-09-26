/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {arrayOf, bool, func, shape, string} from 'prop-types'
import {IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Text} from '@instructure/ui-elements'
import I18n from 'i18n!gradezilla'
import {filterLabels} from '../constants/ViewOptions'

function renderTriggerButton(bindButton) {
  return (
    <Button ref={bindButton} variant="link">
      <Text color="primary">
        {I18n.t('View')} <IconMiniArrowDownSolid />
      </Text>
    </Button>
  )
}

class ViewOptionsMenu extends React.Component {
  static propTypes = {
    columnSortSettings: shape({
      criterion: string.isRequired,
      direction: string.isRequired,
      disabled: bool.isRequired,
      modulesEnabled: bool.isRequired,
      onSortByDefault: func.isRequired,
      onSortByNameAscending: func.isRequired,
      onSortByNameDescending: func.isRequired,
      onSortByDueDateAscending: func.isRequired,
      onSortByDueDateDescending: func.isRequired,
      onSortByPointsAscending: func.isRequired,
      onSortByPointsDescending: func.isRequired,
      onSortByModuleAscending: func.isRequired,
      onSortByModuleDescending: func.isRequired
    }).isRequired,
    filterSettings: shape({
      available: arrayOf(string).isRequired,
      onSelect: func.isRequired,
      selected: arrayOf(string).isRequired
    }),
    teacherNotes: shape({
      disabled: bool.isRequired,
      onSelect: func.isRequired,
      selected: bool.isRequired
    }).isRequired,
    onSelectShowStatusesModal: func.isRequired,
    showUnpublishedAssignments: bool.isRequired,
    onSelectShowUnpublishedAssignments: func.isRequired
  }

  onFilterSelect = (_event, filters) => {
    this.props.filterSettings.onSelect(filters)
  }

  bindMenuContent = menuContent => {
    this.menuContent = menuContent
  }

  bindButton = button => {
    this.button = button
  }

  bindStatusesMenuItem = menuItem => {
    this.statusesMenuItem = menuItem
  }

  bindArrangeByMenuContent = menuContent => {
    this.arrangeByMenuContent = menuContent
  }

  bindFiltersMenuContent = menuContent => {
    this.filtersMenuContent = menuContent
  }

  areColumnsOrderedBy(criterion, direction) {
    const sortSettings = this.props.columnSortSettings
    const result = sortSettings.criterion === criterion

    if (direction === undefined) {
      return result
    } else {
      return result && sortSettings.direction === direction
    }
  }

  focus() {
    this.button.focus()
  }

  render() {
    return (
      <Menu trigger={renderTriggerButton(this.bindButton)} contentRef={this.bindMenuContent}>
        <Menu contentRef={this.bindArrangeByMenuContent} label={I18n.t('Arrange By')}>
          <Menu.Group label={<ScreenReaderContent>{I18n.t('Arrange By')}</ScreenReaderContent>}>
            <Menu.Item
              disabled={this.props.columnSortSettings.disabled}
              selected={this.areColumnsOrderedBy('default')}
              onSelect={this.props.columnSortSettings.onSortByDefault}
            >
              {I18n.t('Default Order')}
            </Menu.Item>

            <Menu.Item
              disabled={this.props.columnSortSettings.disabled}
              selected={this.areColumnsOrderedBy('name', 'ascending')}
              onSelect={this.props.columnSortSettings.onSortByNameAscending}
            >
              {I18n.t('Assignment Name - A-Z')}
            </Menu.Item>

            <Menu.Item
              disabled={this.props.columnSortSettings.disabled}
              selected={this.areColumnsOrderedBy('name', 'descending')}
              onSelect={this.props.columnSortSettings.onSortByNameDescending}
            >
              {I18n.t('Assignment Name - Z-A')}
            </Menu.Item>

            <Menu.Item
              disabled={this.props.columnSortSettings.disabled}
              selected={this.areColumnsOrderedBy('due_date', 'ascending')}
              onSelect={this.props.columnSortSettings.onSortByDueDateAscending}
            >
              {I18n.t('Due Date - Oldest to Newest')}
            </Menu.Item>

            <Menu.Item
              disabled={this.props.columnSortSettings.disabled}
              selected={this.areColumnsOrderedBy('due_date', 'descending')}
              onSelect={this.props.columnSortSettings.onSortByDueDateDescending}
            >
              {I18n.t('Due Date - Newest to Oldest')}
            </Menu.Item>

            <Menu.Item
              disabled={this.props.columnSortSettings.disabled}
              selected={this.areColumnsOrderedBy('points', 'ascending')}
              onSelect={this.props.columnSortSettings.onSortByPointsAscending}
            >
              {I18n.t('Points - Lowest to Highest')}
            </Menu.Item>

            <Menu.Item
              disabled={this.props.columnSortSettings.disabled}
              selected={this.areColumnsOrderedBy('points', 'descending')}
              onSelect={this.props.columnSortSettings.onSortByPointsDescending}
            >
              {I18n.t('Points - Highest to Lowest')}
            </Menu.Item>

            {this.props.columnSortSettings.modulesEnabled && (
              <Menu.Item
                disabled={this.props.columnSortSettings.disabled}
                selected={this.areColumnsOrderedBy('module_position', 'ascending')}
                onSelect={this.props.columnSortSettings.onSortByModuleAscending}
              >
                {I18n.t('Module - First to Last')}
              </Menu.Item>
            )}

            {this.props.columnSortSettings.modulesEnabled && (
              <Menu.Item
                disabled={this.props.columnSortSettings.disabled}
                selected={this.areColumnsOrderedBy('module_position', 'descending')}
                onSelect={this.props.columnSortSettings.onSortByModuleDescending}
              >
                {I18n.t('Module - Last to First')}
              </Menu.Item>
            )}
          </Menu.Group>
        </Menu>

        <Menu.Separator />

        {this.props.filterSettings.available.length > 0 && (
          <Menu contentRef={this.bindFiltersMenuContent} label={I18n.t('Filters')}>
            <Menu.Group
              allowMultiple
              label={<ScreenReaderContent>{I18n.t('Filters')}</ScreenReaderContent>}
              onSelect={this.onFilterSelect}
              selected={this.props.filterSettings.selected}
            >
              {this.props.filterSettings.available.map(filterKey => (
                <Menu.Item key={filterKey} value={filterKey}>
                  {filterLabels[filterKey]}
                </Menu.Item>
              ))}
            </Menu.Group>
          </Menu>
        )}

        {this.props.filterSettings.available.length > 0 && <Menu.Separator />}

        <Menu.Item ref={this.bindStausMenuItem} onSelect={this.props.onSelectShowStatusesModal}>
          {I18n.t('Statuses…')}
        </Menu.Item>

        <Menu.Separator />

        <Menu.Group allowMultiple label={I18n.t('Columns')}>
          <Menu.Item
            disabled={this.props.teacherNotes.disabled}
            onSelect={this.props.teacherNotes.onSelect}
            selected={this.props.teacherNotes.selected}
          >
            <span data-menu-item-id="show-notes-column">{I18n.t('Notes')}</span>
          </Menu.Item>

          <Menu.Item
            selected={this.props.showUnpublishedAssignments}
            onSelect={this.props.onSelectShowUnpublishedAssignments}
          >
            {I18n.t('Unpublished Assignments')}
          </Menu.Item>
        </Menu.Group>
      </Menu>
    )
  }
}

export default ViewOptionsMenu
