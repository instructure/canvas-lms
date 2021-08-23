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
import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'

import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import I18n from 'i18n!gradebook'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import studentRowHeaderConstants from '../../constants/studentRowHeaderConstants'
import ColumnHeader from './ColumnHeader'

export default class StudentColumnHeader extends ColumnHeader {
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
      settingKey: string.isRequired
    }).isRequired,
    selectedEnrollmentFilters: arrayOf(oneOf(studentRowHeaderConstants.enrollmentFilterKeys))
      .isRequired,
    onToggleEnrollmentFilter: func.isRequired,
    disabled: Menu.propTypes.disabled.isRequired,
    onMenuDismiss: Menu.propTypes.onDismiss.isRequired,
    ...ColumnHeader.propTypes
  }

  static defaultProps = {
    loginHandleName: null,
    sisName: null,
    ...ColumnHeader.defaultProps
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
        settingKey
      }
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
        <Menu.Group label={I18n.t('Type')}>
          <Menu.Item
            selected={selectedSortSetting === 'sortable_name'}
            disabled={disabled}
            onSelect={onSortBySortableName}
          >
            <span>{I18n.t('Name')}</span>
          </Menu.Item>

          <Menu.Item
            selected={selectedSortSetting === 'sis_user_id'}
            disabled={disabled}
            onSelect={onSortBySisId}
          >
            <span>{secondaryInfoLabels.sis_id}</span>
          </Menu.Item>

          <Menu.Item
            selected={selectedSortSetting === 'integration_id'}
            disabled={disabled}
            onSelect={onSortByIntegrationId}
          >
            <span>{secondaryInfoLabels.integration_id}</span>
          </Menu.Item>

          <Menu.Item
            selected={selectedSortSetting === 'login_id'}
            disabled={disabled}
            onSelect={onSortByLoginId}
          >
            <span>{secondaryInfoLabels.login_id}</span>
          </Menu.Item>
        </Menu.Group>

        <Menu.Group label={I18n.t('Order')}>
          <Menu.Item
            disabled={disabled}
            key="ascending"
            onSelect={onSortInAscendingOrder}
            selected={selectedSortDirection === 'ascending'}
          >
            <span>{I18n.t('A–Z')}</span>
          </Menu.Item>

          <Menu.Item
            disabled={disabled}
            key="descending"
            onSelect={onSortInDescendingOrder}
            selected={selectedSortDirection === 'descending'}
          >
            <span>{I18n.t('Z–A')}</span>
          </Menu.Item>
        </Menu.Group>
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
                >
                  <Text fontStyle="normal" size="x-small" weight="bold">
                    {I18n.t('Student Name')}
                  </Text>
                </View>
              </Grid.Col>

              <Grid.Col textAlign="center" width="auto">
                <div className={classes}>
                  <Menu
                    contentRef={this.bindOptionsMenuContent}
                    shouldFocusTriggerOnClose={false}
                    trigger={
                      <Button
                        buttonRef={e => (this.optionsMenuTrigger = e)}
                        margin="0"
                        size="small"
                        variant="icon"
                        icon={IconMoreSolid}
                      >
                        <ScreenReaderContent>{I18n.t('Student Name Options')}</ScreenReaderContent>
                      </Button>
                    }
                    onToggle={this.onToggle}
                    onDismiss={this.props.onMenuDismiss}
                  >
                    {sortMenu}

                    <Menu
                      label={I18n.t('Display as')}
                      contentRef={this.bindDisplayAsMenuContent}
                      disabled={this.props.disabled}
                    >
                      <Menu.Group
                        label={<ScreenReaderContent>{I18n.t('Display as')}</ScreenReaderContent>}
                      >
                        <Menu.Item
                          key="first_last"
                          selected={this.props.selectedPrimaryInfo === 'first_last'}
                          onSelect={this.onShowFirstLastNames}
                        >
                          {studentRowHeaderConstants.primaryInfoLabels.first_last}
                        </Menu.Item>
                        <Menu.Item
                          key="last_first"
                          selected={this.props.selectedPrimaryInfo === 'last_first'}
                          onSelect={this.onShowLastFirstNames}
                        >
                          {studentRowHeaderConstants.primaryInfoLabels.last_first}
                        </Menu.Item>
                      </Menu.Group>
                    </Menu>

                    <Menu
                      contentRef={this.bindSecondaryInfoMenuContent}
                      disabled={this.props.disabled}
                      label={I18n.t('Secondary info')}
                    >
                      <Menu.Group
                        label={
                          <ScreenReaderContent>{I18n.t('Secondary info')}</ScreenReaderContent>
                        }
                      >
                        {this.props.sectionsEnabled && (
                          <Menu.Item
                            key="section"
                            selected={this.props.selectedSecondaryInfo === 'section'}
                            onSelect={this.onShowSectionNames}
                          >
                            {studentRowHeaderConstants.secondaryInfoLabels.section}
                          </Menu.Item>
                        )}
                        <Menu.Item
                          key="sis_id"
                          selected={this.props.selectedSecondaryInfo === 'sis_id'}
                          onSelect={this.onShowSisId}
                        >
                          {this.props.sisName ||
                            studentRowHeaderConstants.secondaryInfoLabels.sis_id}
                        </Menu.Item>

                        <Menu.Item
                          key="integration_id"
                          selected={this.props.selectedSecondaryInfo === 'integration_id'}
                          onSelect={this.onShowIntegrationId}
                        >
                          {studentRowHeaderConstants.secondaryInfoLabels.integration_id}
                        </Menu.Item>

                        <Menu.Item
                          key="login_id"
                          selected={this.props.selectedSecondaryInfo === 'login_id'}
                          onSelect={this.onShowLoginId}
                        >
                          {this.props.loginHandleName ||
                            studentRowHeaderConstants.secondaryInfoLabels.login_id}
                        </Menu.Item>

                        {this.props.studentGroupsEnabled && (
                          <Menu.Item
                            key="group"
                            selected={this.props.selectedSecondaryInfo === 'group'}
                            onSelect={this.onShowGroup}
                          >
                            {studentRowHeaderConstants.secondaryInfoLabels.group}
                          </Menu.Item>
                        )}

                        <Menu.Item
                          key="none"
                          selected={this.props.selectedSecondaryInfo === 'none'}
                          onSelect={this.onHideSecondaryInfo}
                        >
                          {studentRowHeaderConstants.secondaryInfoLabels.none}
                        </Menu.Item>
                      </Menu.Group>
                    </Menu>

                    <Menu.Separator />

                    <Menu.Group label={I18n.t('Show')} allowMultiple>
                      <Menu.Item
                        key="inactive"
                        selected={this.props.selectedEnrollmentFilters.includes('inactive')}
                        onSelect={this.onToggleInactive}
                        disabled={this.props.disabled}
                      >
                        {studentRowHeaderConstants.enrollmentFilterLabels.inactive}
                      </Menu.Item>

                      <Menu.Item
                        key="concluded"
                        selected={this.props.selectedEnrollmentFilters.includes('concluded')}
                        onSelect={this.onToggleConcluded}
                        disabled={this.props.disabled}
                      >
                        {studentRowHeaderConstants.enrollmentFilterLabels.concluded}
                      </Menu.Item>
                    </Menu.Group>
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
