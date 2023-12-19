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
import {type PartialStudent} from '@canvas/grading/grading'
import {bool, func, shape, string} from 'prop-types'
import {IconMoreSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'

import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import ColumnHeader from './ColumnHeader'
import {showMessageStudentsWithObserversModal} from '../../../shared/MessageStudentsWithObserversModal'

const I18n = useI18nScope('gradebook')

const {Item: MenuItem, Group: MenuGroup, Separator: MenuSeparator} = Menu as any

function renderTrigger(ref) {
  return (
    <IconButton
      elementRef={ref}
      margin="0"
      size="small"
      renderIcon={IconMoreSolid}
      withBackground={false}
      withBorder={false}
      screenReaderLabel={I18n.t('Total Options')}
    />
  )
}

function TotalDetailContent({viewUngradedAsZero}) {
  if (viewUngradedAsZero) {
    return (
      <View className="Gradebook__ColumnHeaderDetail">
        <View className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
          <Text fontStyle="normal" size="x-small" weight="bold">
            {I18n.t('Total')}
          </Text>
        </View>

        <View className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
          <Text transform="uppercase" weight="bold" fontStyle="normal" size="x-small">
            {I18n.t('Ungraded as 0')}
          </Text>
        </View>
      </View>
    )
  }

  return (
    <View className="Gradebook__ColumnHeaderDetail Gradebook__ColumnHeaderDetail--OneLine">
      <Text fontStyle="normal" size="x-small" weight="bold">
        {I18n.t('Total')}
      </Text>
    </View>
  )
}

TotalDetailContent.propTypes = {
  viewUngradedAsZero: bool.isRequired,
}

type Props = {
  grabFocus?: boolean
  gradeDisplay: any
  isRunningScoreToUngraded?: boolean
  onApplyScoreToUngraded?: any
  onMenuDismiss: any
  position: any
  sortBySetting: any
  viewUngradedAsZero: any
  allStudents: PartialStudent[]
  courseId: string
  messageAttachmentUploadFolderId: string
  userId: string
  showMessageStudentsWithObserversDialog: boolean
  onSendMessageStudentsWho: (args: {recipientsIds: string[]; subject: string; body: string}) => void
}

type State = {
  menuShown: boolean
  hasFocus: boolean
  skipFocusOnClose: boolean
}

export default class TotalGradeColumnHeader extends ColumnHeader<Props, State> {
  bindOptionsMenu: any

  static propTypes = {
    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      onSortByGradeAscending: func.isRequired,
      onSortByGradeDescending: func.isRequired,
      settingKey: string.isRequired,
    }).isRequired,
    gradeDisplay: shape({
      currentDisplay: string.isRequired,
      onSelect: func.isRequired,
      disabled: bool.isRequired,
      hidden: bool.isRequired,
    }).isRequired,
    position: shape({
      isInFront: bool.isRequired,
      isInBack: bool.isRequired,
      onMoveToFront: func.isRequired,
      onMoveToBack: func.isRequired,
    }).isRequired,
    onApplyScoreToUngraded: func,
    onMenuDismiss: Menu.propTypes.onDismiss.isRequired,
    grabFocus: bool,
    pointsBasedGradingScheme: bool.isRequired,
    viewUngradedAsZero: bool.isRequired,
    isRunningScoreToUngraded: bool,
    ...ColumnHeader.propTypes,
  }

  static defaultProps = {
    grabFocus: false,
    ...ColumnHeader.defaultProps,
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

  handleSendMessageStudentsWho = (args: {
    recipientsIds: string[]
    subject: string
    body: string
  }): void => {
    this.props.onSendMessageStudentsWho(args)
  }

  showMessageStudentsWhoDialog(students, courseId) {
    // @ts-expect-error
    this.state.skipFocusOnClose = true
    this.setState({skipFocusOnClose: true})

    const props = {
      assignment: null,
      students: students.filter(student => !student.isInactive && !student.isTestStudent),
      courseId,
      onClose: () => {},
      onSend: this.handleSendMessageStudentsWho,
      messageAttachmentUploadFolderId: this.props.messageAttachmentUploadFolderId,
      userId: this.props.userId,
      pointsBasedGradingScheme: this.props.pointsBasedGradingScheme,
    }

    showMessageStudentsWithObserversModal(props, this.focusAtEnd)
  }

  render() {
    const {sortBySetting, gradeDisplay, position, viewUngradedAsZero} = this.props
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey
    const displayAsPoints = gradeDisplay.currentDisplay === 'points'
    const showSeparator = !gradeDisplay.hidden
    const menuShown = this.state.menuShown
    const allStudents = this.props.allStudents
    const courseId = this.props.courseId
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
                <TotalDetailContent viewUngradedAsZero={viewUngradedAsZero} />
              </Grid.Col>

              <Grid.Col textAlign="center" width="auto">
                <div className={classes}>
                  <Menu
                    menuRef={this.bindOptionsMenuContent}
                    onDismiss={this.props.onMenuDismiss}
                    onToggle={this.onToggle}
                    ref={this.bindOptionsMenu}
                    shouldFocusTriggerOnClose={false}
                    trigger={renderTrigger(ref => (this.optionsMenuTrigger = ref))}
                  >
                    <Menu menuRef={this.bindSortByMenuContent} label={I18n.t('Sort by')}>
                      <MenuGroup
                        label={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}
                      >
                        <MenuItem
                          selected={
                            selectedSortSetting === 'grade' &&
                            sortBySetting.direction === 'ascending'
                          }
                          disabled={sortBySetting.disabled}
                          onSelect={sortBySetting.onSortByGradeAscending}
                        >
                          <span>{I18n.t('Grade - Low to High')}</span>
                        </MenuItem>

                        <MenuItem
                          selected={
                            selectedSortSetting === 'grade' &&
                            sortBySetting.direction === 'descending'
                          }
                          disabled={sortBySetting.disabled}
                          onSelect={sortBySetting.onSortByGradeDescending}
                        >
                          <span>{I18n.t('Grade - High to Low')}</span>
                        </MenuItem>
                      </MenuGroup>
                    </Menu>

                    {showSeparator && <MenuSeparator />}
                    {!gradeDisplay.hidden && (
                      <MenuItem
                        disabled={this.props.gradeDisplay.disabled}
                        onSelect={this.switchGradeDisplay}
                      >
                        <span
                          data-menu-item-id="grade-display-switcher"
                          style={{
                            whiteSpace: 'nowrap',
                          }}
                        >
                          {displayAsPoints
                            ? I18n.t('Display as Percentage')
                            : I18n.t('Display as Points')}
                        </span>
                      </MenuItem>
                    )}

                    {!position.isInFront && (
                      <MenuItem onSelect={position.onMoveToFront}>
                        <span data-menu-item-id="total-grade-move-to-front">
                          {I18n.t('Move to Front')}
                        </span>
                      </MenuItem>
                    )}

                    {!position.isInBack && (
                      <MenuItem onSelect={position.onMoveToBack}>
                        <span data-menu-item-id="total-grade-move-to-back">
                          {I18n.t('Move to End')}
                        </span>
                      </MenuItem>
                    )}

                    {this.props.showMessageStudentsWithObserversDialog && (
                      <MenuItem
                        onSelect={() => this.showMessageStudentsWhoDialog(allStudents, courseId)}
                      >
                        <span data-menu-item-id="total-message-students-who">
                          {I18n.t('Message Students Who')}
                        </span>
                      </MenuItem>
                    )}

                    {this.props.onApplyScoreToUngraded && <MenuSeparator />}

                    {this.props.onApplyScoreToUngraded && (
                      <MenuItem
                        disabled={this.props.isRunningScoreToUngraded}
                        onSelect={this.props.onApplyScoreToUngraded}
                      >
                        {this.props.isRunningScoreToUngraded
                          ? I18n.t('Applying Score to Ungraded')
                          : I18n.t('Apply Score to Ungraded')}
                      </MenuItem>
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
