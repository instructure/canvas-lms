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
import I18n from 'i18n!gradebook'

const { bool, func, shape, string } = React.PropTypes;

function renderTrigger () {
  return (
    <span className="Gradebook__ColumnHeaderAction">
      <Typography weight="bold" fontStyle="normal" size="large" color="brand">
        <IconMoreSolid title={I18n.t('Total Options')} />
      </Typography>
    </span>
  );
}

class TotalGradeColumnHeader extends React.Component {
  static propTypes = {
    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      onSortByGradeAscending: func.isRequired,
      onSortByGradeDescending: func.isRequired,
      settingKey: string.isRequired
    }).isRequired,
    gradeDisplay: shape({
      currentDisplay: string.isRequired,
      onSelect: func.isRequired,
      disabled: bool.isRequired,
      hidden: bool.isRequired
    }).isRequired,
  };

  constructor (props) {
    super(props);

    this.bindOptionsMenuContent = (ref) => { this.optionsMenuContent = ref };
  }

  render () {
    const { sortBySetting, gradeDisplay } = this.props;
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey;
    const displayAsPoints = gradeDisplay.currentDisplay === 'points';
    const showSeparator = !gradeDisplay.hidden;

    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail">
          <Typography weight="normal" fontStyle="normal" size="small">
            { I18n.t('Total') }
          </Typography>
        </span>

        <PopoverMenu
          contentRef={this.bindOptionsMenuContent}
          focusTriggerOnClose={false}
          trigger={renderTrigger()}
        >
          <MenuItemGroup label={I18n.t('Sort by')}>
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

          {
            showSeparator &&
            <MenuItemSeparator />
          }
          {
            !gradeDisplay.hidden &&
            <MenuItem
              disabled={this.props.gradeDisplay.disabled}
              onSelect={this.props.gradeDisplay.onSelect}
            >
              <span data-menu-item-id="grade-display-switcher">
                {displayAsPoints ? I18n.t('Display as Percentage') : I18n.t('Display as Points')}
              </span>
            </MenuItem>
          }
        </PopoverMenu>
      </div>
    );
  }
}

export default TotalGradeColumnHeader
