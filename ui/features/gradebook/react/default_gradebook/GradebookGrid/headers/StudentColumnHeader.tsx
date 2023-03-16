// @ts-nocheck
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
import {arrayOf, bool, func, oneOf, shape, string} from 'prop-types'
import {IconMoreSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'

import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import studentRowHeaderConstants from '../../constants/studentRowHeaderConstants'
import ColumnHeader from './ColumnHeader'

const I18n = useI18nScope('gradebook')

const {Item: MenuItem, Group: MenuGroup, Separator: MenuSeparator} = Menu as any

type Props = {
  disabled: boolean
  loginHandleName?: string
  onMenuDismiss: any
  onSelectPrimaryInfo: any
  onToggleEnrollmentFilter: (enrollmentFilter: string, skipApply?: boolean) => void
  sectionsEnabled: boolean
  selectedEnrollmentFilters: any
  selectedPrimaryInfo: any
  selectedSecondaryInfo: any
  sisName?: string
  studentGroupsEnabled: boolean
  sortBySetting: any
  onSelectSecondaryInfo: any
}

type State = {
  menuShown: boolean
  hasFocus: boolean
}

export default class StudentColumnHeader extends ColumnHeader<Props, State> {
  static propTypes = {
    selectedPrimaryInfo: oneOf(studentRowHeaderConstants.primaryInfoKeys).isRequired,
    onSelectPrimaryInfo: func.isRequired,
    loginHandleName: string,
    sisName: string,
    selectedSecondaryInfo: oneOf(studentRowHeaderConstants.secondaryInfoKeys).isRequired,
    sectionsEnabled: bool.isRequired,
    studentGroupsEnabled: bool.isRequired,
    onSelectSecondaryInfo: func.isRequired,
    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      // sort callbacks with additional sort options enabled
      onSortByIntegrationId: func.isRequired,
      onSortByLoginId: func.isRequired,
      onSortBySisId: func.isRequired,
      onSortBySortableName: func.isRequired,
      onSortInAscendingOrder: func.isRequired,
      onSortInDescendingOrder: func.isRequired,
      // sort callbacks with additional sort options disabled
      onSortBySortableNameAscending: func.isRequired,
      onSortBySortableNameDescending: func.isRequired,
      settingKey: string.isRequired,
    }).isRequired,
    selectedEnrollmentFilters: arrayOf(oneOf(studentRowHeaderConstants.enrollmentFilterKeys))
      .isRequired,
    onToggleEnrollmentFilter: func.isRequired,
    disabled: Menu.propTypes.disabled.isRequired,
    onMenuDismiss: Menu.propTypes.onDismiss.isRequired,
    ...ColumnHeader.propTypes,
  }

  static defaultProps = {
    loginHandleName: null,
    sisName: null,
    ...ColumnHeader.defaultProps,
  }

  getColumnHeaderName() {
    return I18n.t('Student Name')
  }

  getColumnHeaderOptions() {
    return I18n.t('Student Name Options')
  }

  getHeaderTestId() {
    return 'student-column-header'
  }

  showDisplayAsViewOption() {
    return true
  }

  onShowSectionNames = () => {
    this.onSelectSecondaryInfo('section')
  }

  onHideSecondaryInfo = () => {
    this.onSelectSecondaryInfo('none')
  }

  onShowSisId = () => {
    this.onSelectSecondaryInfo('sis_id')
  }

  onShowIntegrationId = () => {
    this.onSelectSecondaryInfo('integration_id')
  }

  onShowLoginId = () => {
    this.onSelectSecondaryInfo('login_id')
  }

  onShowGroup = () => {
    this.onSelectSecondaryInfo('group')
  }

  onShowFirstLastNames = () => {
    this.onSelectPrimaryInfo('first_last')
  }

  onShowLastFirstNames = () => {
    this.onSelectPrimaryInfo('last_first')
  }

  onToggleInactive = () => {
    this.onToggleEnrollmentFilter('inactive')
  }

  onToggleConcluded = () => {
    this.onToggleEnrollmentFilter('concluded')
  }

  onSelectSecondaryInfo(secondaryInfoKey) {
    this.props.onSelectSecondaryInfo(secondaryInfoKey)
  }

  onSelectPrimaryInfo(primaryInfoKey) {
    this.props.onSelectPrimaryInfo(primaryInfoKey)
  }

  onToggleEnrollmentFilter(enrollmentFilterKey) {
    this.props.onToggleEnrollmentFilter(enrollmentFilterKey)
  }

  bindDisplayAsMenuContent = ref => {
    this.bindFlyoutMenu(ref, 'displayAsMenuContent')
  }

  bindSecondaryInfoMenuContent = ref => {
    this.bindFlyoutMenu(ref, 'secondaryInfoMenuContent')
  }

  render() {
    const {
      sortBySetting: {
        direction,
        disabled,
        isSortColumn,
        onSortBySortableName,
        onSortBySisId,
        onSortByIntegrationId,
        onSortByLoginId,
        onSortInAscendingOrder,
        onSortInDescendingOrder,
        settingKey,
      },
    } = this.props
    const selectedSortSetting = isSortColumn && settingKey
    const selectedSortDirection = isSortColumn && direction
    const menuShown = this.state.menuShown
    const classes = `Gradebook__ColumnHeaderAction ${menuShown ? 'menuShown' : ''}`
    const {secondaryInfoLabels} = studentRowHeaderConstants

    const sortMenu = (
      <Menu
        label={I18n.t('Sort by')}
        contentRef={this.bindSortByMenuContent}
        disabled={this.props.disabled}
      >
        <MenuGroup label={I18n.t('Type')}>
          <MenuItem
            selected={selectedSortSetting === 'sortable_name'}
            disabled={disabled}
            onSelect={onSortBySortableName}
          >
            <span>{I18n.t('Name')}</span>
          </MenuItem>

          <MenuItem
            selected={selectedSortSetting === 'sis_user_id'}
            disabled={disabled}
            onSelect={onSortBySisId}
          >
            <span>{secondaryInfoLabels.sis_id}</span>
          </MenuItem>

          <MenuItem
            selected={selectedSortSetting === 'integration_id'}
            disabled={disabled}
            onSelect={onSortByIntegrationId}
          >
            <span>{secondaryInfoLabels.integration_id}</span>
          </MenuItem>

          <MenuItem
            selected={selectedSortSetting === 'login_id'}
            disabled={disabled}
            onSelect={onSortByLoginId}
          >
            <span>{secondaryInfoLabels.login_id}</span>
          </MenuItem>
        </MenuGroup>

        <MenuGroup label={I18n.t('Order')}>
          <MenuItem
            disabled={disabled}
            key="ascending"
            onSelect={onSortInAscendingOrder}
            selected={selectedSortDirection === 'ascending'}
          >
            <span>{I18n.t('A–Z')}</span>
          </MenuItem>

          <MenuItem
            disabled={disabled}
            key="descending"
            onSelect={onSortInDescendingOrder}
            selected={selectedSortDirection === 'descending'}
          >
            <span>{I18n.t('Z–A')}</span>
          </MenuItem>
        </MenuGroup>
      </Menu>
    )

    return (
      <div
        className={`Gradebook__ColumnHeaderContent ${this.state.hasFocus ? 'focused' : ''}`}
        onBlur={this.handleBlur}
        onFocus={this.handleFocus}
      >
        <div style={{flex: 1, minWidth: '1px'}}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <Grid.Row>
              <Grid.Col textAlign="start">
                <View
                  className="Gradebook__ColumnHeaderDetail Gradebook__ColumnHeaderDetail--OneLine"
                  padding="0 0 0 small"
                  data-testid={this.getHeaderTestId()}
                >
                  <Text fontStyle="normal" size="x-small" weight="bold">
                    {this.getColumnHeaderName()}
                  </Text>
                </View>
              </Grid.Col>

              <Grid.Col textAlign="center" width="auto">
                <div className={classes}>
                  <Menu
                    contentRef={this.bindOptionsMenuContent}
                    shouldFocusTriggerOnClose={false}
                    trigger={
                      <IconButton
                        elementRef={e => (this.optionsMenuTrigger = e)}
                        margin="0"
                        size="small"
                        renderIcon={IconMoreSolid}
                        withBackground={false}
                        withBorder={false}
                        screenReaderLabel={this.getColumnHeaderOptions()}
                      />
                    }
                    onToggle={this.onToggle}
                    onDismiss={this.props.onMenuDismiss}
                  >
                    {sortMenu}

                    {this.showDisplayAsViewOption() && (
                      <Menu
                        label={I18n.t('Display as')}
                        contentRef={this.bindDisplayAsMenuContent}
                        disabled={this.props.disabled}
                      >
                        <MenuGroup
                          label={<ScreenReaderContent>{I18n.t('Display as')}</ScreenReaderContent>}
                        >
                          <MenuItem
                            key="first_last"
                            selected={this.props.selectedPrimaryInfo === 'first_last'}
                            onSelect={this.onShowFirstLastNames}
                          >
                            {studentRowHeaderConstants.primaryInfoLabels.first_last}
                          </MenuItem>
                          <MenuItem
                            key="last_first"
                            selected={this.props.selectedPrimaryInfo === 'last_first'}
                            onSelect={this.onShowLastFirstNames}
                          >
                            {studentRowHeaderConstants.primaryInfoLabels.last_first}
                          </MenuItem>
                        </MenuGroup>
                      </Menu>
                    )}

                    <Menu
                      contentRef={this.bindSecondaryInfoMenuContent}
                      disabled={this.props.disabled}
                      label={I18n.t('Secondary info')}
                    >
                      <MenuGroup
                        label={
                          <ScreenReaderContent>{I18n.t('Secondary info')}</ScreenReaderContent>
                        }
                      >
                        {this.props.sectionsEnabled && (
                          <MenuItem
                            key="section"
                            selected={this.props.selectedSecondaryInfo === 'section'}
                            onSelect={this.onShowSectionNames}
                          >
                            {studentRowHeaderConstants.secondaryInfoLabels.section}
                          </MenuItem>
                        )}
                        <MenuItem
                          key="sis_id"
                          selected={this.props.selectedSecondaryInfo === 'sis_id'}
                          onSelect={this.onShowSisId}
                        >
                          {this.props.sisName ||
                            studentRowHeaderConstants.secondaryInfoLabels.sis_id}
                        </MenuItem>

                        <MenuItem
                          key="integration_id"
                          selected={this.props.selectedSecondaryInfo === 'integration_id'}
                          onSelect={this.onShowIntegrationId}
                        >
                          {studentRowHeaderConstants.secondaryInfoLabels.integration_id}
                        </MenuItem>

                        <MenuItem
                          key="login_id"
                          selected={this.props.selectedSecondaryInfo === 'login_id'}
                          onSelect={this.onShowLoginId}
                        >
                          {this.props.loginHandleName ||
                            studentRowHeaderConstants.secondaryInfoLabels.login_id}
                        </MenuItem>

                        {this.props.studentGroupsEnabled && (
                          <MenuItem
                            key="group"
                            selected={this.props.selectedSecondaryInfo === 'group'}
                            onSelect={this.onShowGroup}
                          >
                            {studentRowHeaderConstants.secondaryInfoLabels.group}
                          </MenuItem>
                        )}

                        <MenuItem
                          key="none"
                          selected={this.props.selectedSecondaryInfo === 'none'}
                          onSelect={this.onHideSecondaryInfo}
                        >
                          {studentRowHeaderConstants.secondaryInfoLabels.none}
                        </MenuItem>
                      </MenuGroup>
                    </Menu>

                    <MenuSeparator />

                    <MenuGroup label={I18n.t('Show')} allowMultiple={true}>
                      <MenuItem
                        key="inactive"
                        selected={this.props.selectedEnrollmentFilters.includes('inactive')}
                        onSelect={this.onToggleInactive}
                        disabled={this.props.disabled}
                      >
                        {studentRowHeaderConstants.enrollmentFilterLabels.inactive}
                      </MenuItem>

                      <MenuItem
                        key="concluded"
                        selected={this.props.selectedEnrollmentFilters.includes('concluded')}
                        onSelect={this.onToggleConcluded}
                        disabled={this.props.disabled}
                      >
                        {studentRowHeaderConstants.enrollmentFilterLabels.concluded}
                      </MenuItem>
                    </MenuGroup>
                  </Menu>
                </div>
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </div>
      </div>
    )
  }
}
