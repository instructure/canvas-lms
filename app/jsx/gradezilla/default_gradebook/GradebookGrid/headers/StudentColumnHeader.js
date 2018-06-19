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

import React from 'react';
import { arrayOf, bool, func, oneOf, shape, string } from 'prop-types';
import IconMoreSolid from 'instructure-icons/lib/Solid/IconMoreSolid';
import Button from '@instructure/ui-core/lib/components/Button';
import Container from '@instructure/ui-core/lib/components/Container';
import Grid, { GridCol, GridRow } from '@instructure/ui-core/lib/components/Grid';
import {
  MenuItem,
  MenuItemFlyout,
  MenuItemGroup,
  MenuItemSeparator
} from '@instructure/ui-core/lib/components/Menu';
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu';
import Text from '@instructure/ui-core/lib/components/Text';
import I18n from 'i18n!gradebook';
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent';
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
    onSelectSecondaryInfo: func.isRequired,
    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      onSortBySortableNameAscending: func.isRequired,
      onSortBySortableNameDescending: func.isRequired,
      settingKey: string.isRequired
    }).isRequired,
    selectedEnrollmentFilters: arrayOf(oneOf(studentRowHeaderConstants.enrollmentFilterKeys)).isRequired,
    onToggleEnrollmentFilter: func.isRequired,
    disabled: bool.isRequired,
    onMenuClose: func.isRequired,
    ...ColumnHeader.propTypes
  };

  static defaultProps = {
    loginHandleName: null,
    sisName: null,
    ...ColumnHeader.defaultProps
  };

  onShowSectionNames = () => { this.onSelectSecondaryInfo('section'); };
  onHideSecondaryInfo = () => { this.onSelectSecondaryInfo('none'); };
  onShowSisId = () => { this.onSelectSecondaryInfo('sis_id'); };
  onShowLoginId = () => { this.onSelectSecondaryInfo('login_id'); };

  onShowFirstLastNames = () => { this.onSelectPrimaryInfo('first_last'); };
  onShowLastFirstNames = () => { this.onSelectPrimaryInfo('last_first'); };

  onToggleInactive = () => { this.onToggleEnrollmentFilter('inactive'); };
  onToggleConcluded = () => { this.onToggleEnrollmentFilter('concluded'); };

  onSelectSecondaryInfo (secondaryInfoKey) {
    this.props.onSelectSecondaryInfo(secondaryInfoKey);
  }

  onSelectPrimaryInfo (primaryInfoKey) {
    this.props.onSelectPrimaryInfo(primaryInfoKey);
  }

  onToggleEnrollmentFilter (enrollmentFilterKey) {
    this.props.onToggleEnrollmentFilter(enrollmentFilterKey);
  }

  bindDisplayAsMenuContent = (ref) => {
    this.displayAsMenuContent = ref;
    this.bindFlyoutMenu(ref, this.displayAsMenuContent);
  };

  bindSecondaryInfoMenuContent = (ref) => {
    this.secondaryInfoMenuContent = ref;
    this.bindFlyoutMenu(ref, this.secondaryInfoMenuContent);
  };

  render () {
    const {
      sortBySetting: {
        isSortColumn,
        settingKey,
        direction,
        disabled,
        onSortBySortableNameAscending,
        onSortBySortableNameDescending
      }
    } = this.props;
    const selectedSortSetting = isSortColumn && settingKey;
    const menuShown = this.state.menuShown;
    const classes = `Gradebook__ColumnHeaderAction ${menuShown ? 'menuShown' : ''}`;

    return (
      <div
        className={`Gradebook__ColumnHeaderContent ${this.state.hasFocus ? 'focused' : ''}`}
        onBlur={this.handleBlur}
        onFocus={this.handleFocus}
      >
        <div style={{ flex: 1, minWidth: '1px' }}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <GridRow>
              <GridCol textAlign="start">
                <Container className="Gradebook__ColumnHeaderDetail" padding="0 0 0 small">
                  <Text fontStyle="normal" size="x-small" weight="bold">{ I18n.t('Student Name') }</Text>
                </Container>
              </GridCol>

              <GridCol textAlign="center" width="auto">
                <div className={classes}>
                  <PopoverMenu
                    contentRef={this.bindOptionsMenuContent}
                    shouldFocusTriggerOnClose={false}
                    trigger={
                      <Button buttonRef={this.bindOptionsMenuTrigger} margin="0" size="small" variant="icon">
                        <IconMoreSolid title={I18n.t('Student Name Options')} />
                      </Button>
                    }
                    onToggle={this.onToggle}
                    onClose={this.props.onMenuClose}
                  >
                    <MenuItemFlyout label={I18n.t('Sort by')} contentRef={this.bindSortByMenuContent} disabled={this.props.disabled}>
                      <MenuItemGroup label={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
                        <MenuItem
                          selected={selectedSortSetting === 'sortable_name' && direction === 'ascending'}
                          disabled={disabled}
                          onSelect={onSortBySortableNameAscending}
                        >
                          <span>{I18n.t('A–Z')}</span>
                        </MenuItem>

                        <MenuItem
                          selected={selectedSortSetting === 'sortable_name' && direction === 'descending'}
                          disabled={disabled}
                          onSelect={onSortBySortableNameDescending}
                        >
                          <span>{I18n.t('Z–A')}</span>
                        </MenuItem>
                      </MenuItemGroup>
                    </MenuItemFlyout>

                    <MenuItemFlyout label={I18n.t('Display as')} contentRef={this.bindDisplayAsMenuContent} disabled={this.props.disabled}>
                      <MenuItemGroup label={<ScreenReaderContent>{I18n.t('Display as')}</ScreenReaderContent>}>
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
                      </MenuItemGroup>
                    </MenuItemFlyout>

                    <MenuItemFlyout
                      contentRef={this.bindSecondaryInfoMenuContent}
                      disabled={this.props.disabled}
                      label={I18n.t('Secondary info')}
                    >
                      <MenuItemGroup label={<ScreenReaderContent>{I18n.t('Secondary info')}</ScreenReaderContent>}>
                        {
                          this.props.sectionsEnabled &&
                          <MenuItem
                            key="section"
                            selected={this.props.selectedSecondaryInfo === 'section'}
                            onSelect={this.onShowSectionNames}
                          >
                            {studentRowHeaderConstants.secondaryInfoLabels.section}
                          </MenuItem>
                        }
                        <MenuItem
                          key="sis_id"
                          selected={this.props.selectedSecondaryInfo === 'sis_id'}
                          onSelect={this.onShowSisId}
                        >
                          {this.props.sisName || studentRowHeaderConstants.secondaryInfoLabels.sis_id}
                        </MenuItem>

                        <MenuItem
                          key="login_id"
                          selected={this.props.selectedSecondaryInfo === 'login_id'}
                          onSelect={this.onShowLoginId}
                        >
                          {this.props.loginHandleName || studentRowHeaderConstants.secondaryInfoLabels.login_id}
                        </MenuItem>

                        <MenuItem
                          key="none"
                          selected={this.props.selectedSecondaryInfo === 'none'}
                          onSelect={this.onHideSecondaryInfo}
                        >
                          {studentRowHeaderConstants.secondaryInfoLabels.none}
                        </MenuItem>
                      </MenuItemGroup>
                    </MenuItemFlyout>

                    <MenuItemSeparator />

                    <MenuItemGroup label={I18n.t('Show')} allowMultiple>
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
                    </MenuItemGroup>
                  </PopoverMenu>
                </div>
              </GridCol>
            </GridRow>
          </Grid>
        </div>
      </div>
    );
  }
}
