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
import { bool, func, number, shape, string } from 'prop-types';
import IconMoreSolid from 'instructure-icons/lib/Solid/IconMoreSolid';
import Button from '@instructure/ui-core/lib/components/Button';
import Grid, { GridCol, GridRow } from '@instructure/ui-core/lib/components/Grid';
import { MenuItem, MenuItemFlyout, MenuItemGroup } from '@instructure/ui-core/lib/components/Menu';
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu';
import Text from '@instructure/ui-core/lib/components/Text';
import I18n from 'i18n!gradebook';
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent';
import ColumnHeader from './ColumnHeader'

function AssignmentGroupDetail ({ assignmentGroup, weightedGroups }) {
  if (weightedGroups) {
    const weightValue = assignmentGroup.groupWeight || 0;
    const weightStr = I18n.n(weightValue, { precision: 2, percentage: true, strip_insignificant_zeros: true });

    return (
      <span className="Gradebook__ColumnHeaderDetail">
        <span className="Gradebook__ColumnHeaderDetailLine">
          { assignmentGroup.name }
        </span>

        <span className="Gradebook__ColumnHeaderDetailLine">
          <Text weight="normal" fontStyle="normal" size="x-small">
            { I18n.t('%{weight} of grade', { weight: weightStr }) }
          </Text>
        </span>
      </span>
    );
  }

  return (
    <span className="Gradebook__ColumnHeaderDetail">{ assignmentGroup.name }</span>
  );
}

AssignmentGroupDetail.propTypes = {
  assignmentGroup: shape({
    name: string.isRequired,
    groupWeight: number
  }).isRequired,
  weightedGroups: bool.isRequired
}

function renderTrigger (assignmentGroup, ref) {
  return (
    <Button buttonRef={ref} margin="0" size="small" variant="icon">
      <IconMoreSolid title={I18n.t('%{name} Options', { name: assignmentGroup.name })} />
    </Button>
  );
}

export default class AssignmentGroupColumnHeader extends ColumnHeader {
  static propTypes = {
    assignmentGroup: shape({
      name: string.isRequired,
      groupWeight: number
    }).isRequired,
    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      onSortByGradeAscending: func.isRequired,
      onSortByGradeDescending: func.isRequired,
      settingKey: string.isRequired
    }).isRequired,
    weightedGroups: bool.isRequired,
    onMenuClose: func.isRequired,
    ...ColumnHeader.propTypes
  };

  static defaultProps = {
    ...ColumnHeader.defaultProps
  };

  render () {
    const { assignmentGroup, sortBySetting, weightedGroups } = this.props;
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey;
    const classes = `Gradebook__ColumnHeaderAction ${this.state.menuShown ? 'menuShown' : ''}`;

    return (
      <div
        className={`Gradebook__ColumnHeaderContent ${this.state.hasFocus ? 'focused' : ''}`}
        onBlur={this.handleBlur}
        onFocus={this.handleFocus}
      >
        <div style={{ flex: 1, minWidth: '1px' }}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <GridRow>
              <GridCol textAlign="center" width="auto">
                <div className="Gradebook__ColumnHeaderIndicators" />
              </GridCol>

              <GridCol textAlign="center">
                <AssignmentGroupDetail assignmentGroup={assignmentGroup} weightedGroups={weightedGroups} />
              </GridCol>

              <GridCol textAlign="center" width="auto">
                <div className={classes}>
                  <PopoverMenu
                    contentRef={this.bindOptionsMenuContent}
                    shouldFocusTriggerOnClose={false}
                    trigger={renderTrigger(this.props.assignmentGroup, this.bindOptionsMenuTrigger)}
                    onToggle={this.onToggle}
                    onClose={this.props.onMenuClose}
                  >
                    <MenuItemFlyout label={I18n.t('Sort by')} contentRef={this.bindSortByMenuContent}>
                      <MenuItemGroup label={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
                        <MenuItem
                          selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'ascending'}
                          disabled={sortBySetting.disabled}
                          onSelect={sortBySetting.onSortByGradeAscending}
                        >
                          <span>{I18n.t('Grade - Low to High')}</span>
                        </MenuItem>

                        <MenuItem
                          selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'descending'}
                          disabled={sortBySetting.disabled}
                          onSelect={sortBySetting.onSortByGradeDescending}
                        >
                          <span>{I18n.t('Grade - High to Low')}</span>
                        </MenuItem>
                      </MenuItemGroup>
                    </MenuItemFlyout>
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
