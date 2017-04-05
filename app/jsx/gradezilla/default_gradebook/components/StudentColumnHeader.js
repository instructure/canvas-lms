/*
 * Copyright (C) 2017 Instructure, Inc.
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
import IconMoreSolid from 'instructure-icons/react/Solid/IconMoreSolid'
import { MenuItem, MenuItemGroup, MenuItemSeparator } from 'instructure-ui/lib/components/Menu'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu'
import Typography from 'instructure-ui/lib/components/Typography'
import StudentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/StudentRowHeaderConstants'
import I18n from 'i18n!gradebook'

const { arrayOf, bool, func, oneOf, shape, string } = React.PropTypes;

export default class StudentColumnHeader extends React.Component {
  static propTypes = {
    selectedPrimaryInfo: oneOf(StudentRowHeaderConstants.primaryInfoKeys).isRequired,
    onSelectPrimaryInfo: func.isRequired,
    loginHandleName: string,
    selectedSecondaryInfo: oneOf(StudentRowHeaderConstants.secondaryInfoKeys).isRequired,
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
    selectedEnrollmentFilters: arrayOf(oneOf(StudentRowHeaderConstants.enrollmentFilterKeys)).isRequired,
    onToggleEnrollmentFilter: func.isRequired
  };

  static defaultProps = {
    loginHandleName: null
  };

  constructor (props) {
    super(props);

    this.bindOptionsMenuContent = (ref) => { this.optionsMenuContent = ref };
    this.onShowSectionNames = this.onSelectSecondaryInfo.bind(this, 'section');
    this.onHideSecondaryInfo = this.onSelectSecondaryInfo.bind(this, 'none');
    this.onShowSisId = this.onSelectSecondaryInfo.bind(this, 'sis_id');
    this.onShowLoginId = this.onSelectSecondaryInfo.bind(this, 'login_id');

    this.onShowFirstLastNames = this.onSelectPrimaryInfo.bind(this, 'first_last');
    this.onShowLastFirstNames = this.onSelectPrimaryInfo.bind(this, 'last_first');
    this.onHideStudentNames = this.onSelectPrimaryInfo.bind(this, 'anonymous');

    this.onToggleInactive = this.onToggleEnrollmentFilter.bind(this, 'inactive');
    this.onToggleConcluded = this.onToggleEnrollmentFilter.bind(this, 'concluded');
  }

  onSelectSecondaryInfo (secondaryInfoKey) {
    this.props.onSelectSecondaryInfo(secondaryInfoKey);
  }

  onSelectPrimaryInfo (primaryInfoKey) {
    this.props.onSelectPrimaryInfo(primaryInfoKey);
  }

  onToggleEnrollmentFilter (enrollmentFilterKey) {
    this.props.onToggleEnrollmentFilter(enrollmentFilterKey);
  }

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

    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail">
          <Typography weight="normal" fontStyle="normal" size="small">
            { I18n.t('Student Name') }
          </Typography>
        </span>

        <PopoverMenu
          contentRef={this.bindOptionsMenuContent}
          focusTriggerOnClose={false}
          trigger={
            <span className="Gradebook__ColumnHeaderAction">
              <Typography weight="bold" fontStyle="normal" size="large" color="brand">
                <IconMoreSolid title={I18n.t('Student Name Options')} />
              </Typography>
            </span>
          }
        >
          <MenuItemGroup label={I18n.t('Sort by')}>
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
          <MenuItemSeparator />
          <MenuItemGroup label={I18n.t('Display as')} data-menu-item-group-id="primary-info">
            <MenuItem
              key="first_last"
              data-menu-item-id="first_last"
              selected={this.props.selectedPrimaryInfo === 'first_last'}
              onSelect={this.onShowFirstLastNames}
            >
              {StudentRowHeaderConstants.primaryInfoLabels.first_last}
            </MenuItem>
            <MenuItem
              key="last_first"
              data-menu-item-id="last_first"
              selected={this.props.selectedPrimaryInfo === 'last_first'}
              onSelect={this.onShowLastFirstNames}
            >
              {StudentRowHeaderConstants.primaryInfoLabels.last_first}
            </MenuItem>
            <MenuItem
              key="anonymous"
              data-menu-item-id="anonymous"
              selected={this.props.selectedPrimaryInfo === 'anonymous'}
              onSelect={this.onHideStudentNames}
            >
              {StudentRowHeaderConstants.primaryInfoLabels.anonymous}
            </MenuItem>
          </MenuItemGroup>
          <MenuItemSeparator />
          <MenuItemGroup label={I18n.t('Secondary info')} data-menu-item-group-id="secondary-info">
            {
              this.props.sectionsEnabled &&
              <MenuItem
                key="section"
                data-menu-item-id="section"
                selected={this.props.selectedSecondaryInfo === 'section'}
                onSelect={this.onShowSectionNames}
              >
                {StudentRowHeaderConstants.secondaryInfoLabels.section}
              </MenuItem>
            }
            <MenuItem
              key="sis_id"
              data-menu-item-id="sis_id"
              selected={this.props.selectedSecondaryInfo === 'sis_id'}
              onSelect={this.onShowSisId}
            >
              {StudentRowHeaderConstants.secondaryInfoLabels.sis_id}
            </MenuItem>

            <MenuItem
              key="login_id"
              data-menu-item-id="login_id"
              selected={this.props.selectedSecondaryInfo === 'login_id'}
              onSelect={this.onShowLoginId}
            >
              {this.props.loginHandleName || StudentRowHeaderConstants.secondaryInfoLabels.login_id}
            </MenuItem>

            <MenuItem
              key="none"
              data-menu-item-id="none"
              selected={this.props.selectedSecondaryInfo === 'none'}
              onSelect={this.onHideSecondaryInfo}
            >
              {StudentRowHeaderConstants.secondaryInfoLabels.none}
            </MenuItem>
          </MenuItemGroup>

          <MenuItemSeparator />

          <MenuItemGroup label={I18n.t('Show')} data-menu-item-group-id="enrollment-filter" allowMultiple>
            <MenuItem
              key="inactive"
              data-menu-item-id="inactive"
              selected={this.props.selectedEnrollmentFilters.includes('inactive')}
              onSelect={this.onToggleInactive}
            >
              {StudentRowHeaderConstants.enrollmentFilterLabels.inactive}
            </MenuItem>

            <MenuItem
              key="concluded"
              data-menu-item-id="concluded"
              selected={this.props.selectedEnrollmentFilters.includes('concluded')}
              onSelect={this.onToggleConcluded}
            >
              {StudentRowHeaderConstants.enrollmentFilterLabels.concluded}
            </MenuItem>
          </MenuItemGroup>
        </PopoverMenu>
      </div>
    );
  }
}
