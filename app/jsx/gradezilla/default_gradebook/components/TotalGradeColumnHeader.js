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
import { bool, func, shape, string } from 'prop-types';
import IconMoreSolid from 'instructure-icons/lib/Solid/IconMoreSolid';
import {
  MenuItem,
  MenuItemFlyout,
  MenuItemGroup,
  MenuItemSeparator
} from 'instructure-ui/lib/components/Menu';
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu';
import Typography from 'instructure-ui/lib/components/Typography';
import I18n from 'i18n!gradebook';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import ColumnHeader from 'jsx/gradezilla/default_gradebook/components/ColumnHeader';

function renderTrigger (menuShown, ref) {
  const classes = `Gradebook__ColumnHeaderAction ${menuShown ? 'menuShown' : ''}`;

  return (
    <span ref={ref} className={classes}>
      <Typography weight="bold" fontStyle="normal" size="large" color="brand">
        <IconMoreSolid className="rotated" title={I18n.t('Total Options')} />
      </Typography>
    </span>
  );
}

class TotalGradeColumnHeader extends ColumnHeader {
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
    position: shape({
      isInFront: bool.isRequired,
      isInBack: bool.isRequired,
      onMoveToFront: func.isRequired,
      onMoveToBack: func.isRequired
    }).isRequired,
    onMenuClose: func.isRequired,
    grabFocus: bool,
    ...ColumnHeader.propTypes
  };

  static defaultProps = {
    grabFocus: false,
    ...ColumnHeader.defaultProps
  };

  state = { menuShown: false, skipFocusOnClose: false };

  switchGradeDisplay = () => { this.invokeAndSkipFocus(this.props.gradeDisplay) };

  invokeAndSkipFocus (action) {
    this.setState({ skipFocusOnClose: true });
    action.onSelect(this.focusAtEnd);
  }

  componentDidMount () {
    if (this.props.grabFocus) {
      this.focusAtEnd();
    }
  }

  render () {
    const { sortBySetting, gradeDisplay, position } = this.props;
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey;
    const displayAsPoints = gradeDisplay.currentDisplay === 'points';
    const showSeparator = !gradeDisplay.hidden;
    const nowrapStyle = {
      whiteSpace: 'nowrap'
    };
    const menuShown = this.state.menuShown;

    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail">
          <Typography weight="normal" fontStyle="normal" size="small">
            { I18n.t('Total') }
          </Typography>
        </span>

        <PopoverMenu
          ref={this.bindOptionsMenu}
          contentRef={this.bindOptionsMenuContent}
          shouldFocusTriggerOnClose={false}
          trigger={renderTrigger(menuShown, this.bindOptionsMenuTrigger)}
          onToggle={this.onToggle}
          onClose={this.props.onMenuClose}
        >
          <MenuItemFlyout contentRef={this.bindSortByMenuContent} label={I18n.t('Sort by')}>
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

          {
            showSeparator &&
            <MenuItemSeparator />
          }
          {
            !gradeDisplay.hidden &&
            <MenuItem
              disabled={this.props.gradeDisplay.disabled}
              onSelect={this.switchGradeDisplay}
            >
              <span data-menu-item-id="grade-display-switcher" style={nowrapStyle}>
                {displayAsPoints ? I18n.t('Display as Percentage') : I18n.t('Display as Points')}
              </span>
            </MenuItem>
          }

          {
            !position.isInFront &&
            <MenuItem onSelect={position.onMoveToFront}>
              <span data-menu-item-id="total-grade-move-to-front">
                {I18n.t('Move to Front')}
              </span>
            </MenuItem>
          }

          {
            !position.isInBack &&
            <MenuItem onSelect={position.onMoveToBack}>
              <span data-menu-item-id="total-grade-move-to-back">
                {I18n.t('Move to End')}
              </span>
            </MenuItem>
          }
        </PopoverMenu>
      </div>
    );
  }
}

export default TotalGradeColumnHeader;
