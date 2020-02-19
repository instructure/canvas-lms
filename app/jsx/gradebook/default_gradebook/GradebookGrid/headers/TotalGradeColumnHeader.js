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
import {bool, func, shape, string} from 'prop-types'
import {IconMoreSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {View, Grid} from '@instructure/ui-layout'

import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-elements'
import I18n from 'i18n!gradebook'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import ColumnHeader from './ColumnHeader'

function renderTrigger(ref) {
  return (
    <Button buttonRef={ref} margin="0" size="small" variant="icon" icon={IconMoreSolid}>
      <ScreenReaderContent>{I18n.t('Total Options')}</ScreenReaderContent>
    </Button>
  )
}

export default class TotalGradeColumnHeader extends ColumnHeader {
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
    onMenuDismiss: Menu.propTypes.onDismiss.isRequired,
    grabFocus: bool,
    ...ColumnHeader.propTypes
  }

  static defaultProps = {
    grabFocus: false,
    ...ColumnHeader.defaultProps
  }

  switchGradeDisplay = () => {
    this.invokeAndSkipFocus(this.props.gradeDisplay)
  }

  invokeAndSkipFocus(action) {
    this.setState({skipFocusOnClose: true})
    action.onSelect(this.focusAtEnd)
  }

  componentDidMount() {
    if (this.props.grabFocus) {
      this.focusAtEnd()
    }
  }

  render() {
    const {sortBySetting, gradeDisplay, position} = this.props
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey
    const displayAsPoints = gradeDisplay.currentDisplay === 'points'
    const showSeparator = !gradeDisplay.hidden
    const nowrapStyle = {
      whiteSpace: 'nowrap'
    }
    const menuShown = this.state.menuShown
    const classes = `Gradebook__ColumnHeaderAction ${menuShown ? 'menuShown' : ''}`

    return (
      <div
        className={`Gradebook__ColumnHeaderContent ${this.state.hasFocus ? 'focused' : ''}`}
        onBlur={this.handleBlur}
        onFocus={this.handleFocus}
      >
        <div style={{flex: 1, minWidth: '1px'}}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <Grid.Row>
              <Grid.Col textAlign="center" width="auto">
                <div className="Gradebook__ColumnHeaderIndicators" />
              </Grid.Col>

              <Grid.Col textAlign="center">
                <View className="Gradebook__ColumnHeaderDetail">
                  <Text fontStyle="normal" size="x-small" weight="bold">
                    {I18n.t('Total')}
                  </Text>
                </View>
              </Grid.Col>

              <Grid.Col textAlign="center" width="auto">
                <div className={classes}>
                  <Menu
                    contentRef={this.bindOptionsMenuContent}
                    onDismiss={this.props.onMenuDismiss}
                    onToggle={this.onToggle}
                    ref={this.bindOptionsMenu}
                    shouldFocusTriggerOnClose={false}
                    trigger={renderTrigger(ref => (this.optionsMenuTrigger = ref))}
                  >
                    <Menu contentRef={this.bindSortByMenuContent} label={I18n.t('Sort by')}>
                      <Menu.Group
                        label={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}
                      >
                        <Menu.Item
                          selected={
                            selectedSortSetting === 'grade' &&
                            sortBySetting.direction === 'ascending'
                          }
                          disabled={sortBySetting.disabled}
                          onSelect={sortBySetting.onSortByGradeAscending}
                        >
                          <span>{I18n.t('Grade - Low to High')}</span>
                        </Menu.Item>

                        <Menu.Item
                          selected={
                            selectedSortSetting === 'grade' &&
                            sortBySetting.direction === 'descending'
                          }
                          disabled={sortBySetting.disabled}
                          onSelect={sortBySetting.onSortByGradeDescending}
                        >
                          <span>{I18n.t('Grade - High to Low')}</span>
                        </Menu.Item>
                      </Menu.Group>
                    </Menu>

                    {showSeparator && <Menu.Separator />}
                    {!gradeDisplay.hidden && (
                      <Menu.Item
                        disabled={this.props.gradeDisplay.disabled}
                        onSelect={this.switchGradeDisplay}
                      >
                        <span data-menu-item-id="grade-display-switcher" style={nowrapStyle}>
                          {displayAsPoints
                            ? I18n.t('Display as Percentage')
                            : I18n.t('Display as Points')}
                        </span>
                      </Menu.Item>
                    )}

                    {!position.isInFront && (
                      <Menu.Item onSelect={position.onMoveToFront}>
                        <span data-menu-item-id="total-grade-move-to-front">
                          {I18n.t('Move to Front')}
                        </span>
                      </Menu.Item>
                    )}

                    {!position.isInBack && (
                      <Menu.Item onSelect={position.onMoveToBack}>
                        <span data-menu-item-id="total-grade-move-to-back">
                          {I18n.t('Move to End')}
                        </span>
                      </Menu.Item>
                    )}
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
