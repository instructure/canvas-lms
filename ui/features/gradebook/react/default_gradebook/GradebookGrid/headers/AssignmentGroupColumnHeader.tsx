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
import {bool, func, number, shape, string} from 'prop-types'
import {IconMoreSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import ColumnHeader from './ColumnHeader'
import {showMessageStudentsWithObserversModal} from '../../../shared/MessageStudentsWithObserversModal'

const I18n = useI18nScope('gradebook')

function AssignmentGroupDetail({assignmentGroup, viewUngradedAsZero, weightedGroups}) {
  if (weightedGroups || viewUngradedAsZero) {
    let secondaryLine, secondaryLineExt

    if (weightedGroups) {
      const weightValue = assignmentGroup.groupWeight || 0
      const weight = I18n.n(weightValue, {
        precision: 2,
        percentage: true,
        strip_insignificant_zeros: true,
      })

      if (viewUngradedAsZero) {
        secondaryLine = I18n.t('%{weight} of grade/', {weight})
        secondaryLineExt = I18n.t('Ungraded as 0')
      } else {
        secondaryLine = I18n.t('%{weight} of grade', {weight})
      }
    } else {
      secondaryLineExt = I18n.t('Ungraded as 0')
    }

    return (
      <span className="Gradebook__ColumnHeaderDetail">
        <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
          {assignmentGroup.name}
        </span>

        <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
          <Text weight="normal" fontStyle="normal" size="x-small">
            {secondaryLine}
            {typeof secondaryLineExt !== 'undefined' && secondaryLineExt.length > 0 && (
              <Text weight="bold" transform="uppercase" fontStyle="normal" size="x-small">
                {secondaryLineExt}
              </Text>
            )}
          </Text>
        </span>
      </span>
    )
  }

  return (
    <span className="Gradebook__ColumnHeaderDetail Gradebook__ColumnHeaderDetail--OneLine">
      {assignmentGroup.name}
    </span>
  )
}

AssignmentGroupDetail.propTypes = {
  assignmentGroup: shape({
    name: string.isRequired,
    groupWeight: number,
  }).isRequired,
  viewUngradedAsZero: bool.isRequired,
  weightedGroups: bool.isRequired,
}

function renderTrigger(assignmentGroup, ref) {
  return (
    <IconButton
      elementRef={ref}
      margin="0"
      size="small"
      color="secondary"
      renderIcon={IconMoreSolid}
      screenReaderLabel={I18n.t('%{name} Options', {name: assignmentGroup.name})}
    />
  )
}

type Props = {
  onApplyScoreToUngraded?: any
  isRunningScoreToUngraded: any
  assignmentGroup: any
  sortBySetting: any
  viewUngradedAsZero: any
  weightedGroups: any
  onMenuDismiss: any
  allStudents: PartialStudent[]
  courseId: string
  messageAttachmentUploadFolderId: string
  userId: string
  showMessageStudentsWithObserversDialog: boolean
  onSendMessageStudentsWho: (args: {recipientsIds: string[]; subject: string; body: string}) => void
}

type State = {
  onApplyScoreToUngraded: any
  hasFocus: boolean
  menuShown: boolean
}

export default class AssignmentGroupColumnHeader extends ColumnHeader<Props, State> {
  static propTypes = {
    assignmentGroup: shape({
      name: string.isRequired,
      groupWeight: number,
    }).isRequired,
    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      onSortByGradeAscending: func.isRequired,
      onSortByGradeDescending: func.isRequired,
      settingKey: string.isRequired,
    }).isRequired,
    onApplyScoreToUngraded: func,
    pointsBasedGradingScheme: bool.isRequired,
    viewUngradedAsZero: bool.isRequired,
    weightedGroups: bool.isRequired,
    onMenuDismiss: Menu.propTypes.onDismiss.isRequired,
    isRunningScoreToUngraded: bool,
    ...ColumnHeader.propTypes,
  }

  static defaultProps = {
    ...ColumnHeader.defaultProps,
  }

  handleSendMessageStudentsWho = (args: {
    recipientsIds: string[]
    subject: string
    body: string
  }): void => {
    this.props.onSendMessageStudentsWho(args)
  }

  async showMessageStudentsWhoDialog(students, courseId) {
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
    const {assignmentGroup, sortBySetting, viewUngradedAsZero, weightedGroups} = this.props
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey
    const allStudents = this.props.allStudents
    const courseId = this.props.courseId
    const classes = `Gradebook__ColumnHeaderAction ${this.state.menuShown ? 'menuShown' : ''}`

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
                <AssignmentGroupDetail
                  assignmentGroup={assignmentGroup}
                  weightedGroups={weightedGroups}
                  viewUngradedAsZero={viewUngradedAsZero}
                />
              </Grid.Col>

              <Grid.Col textAlign="center" width="auto">
                <div className={classes}>
                  <Menu
                    menuRef={this.bindOptionsMenuContent}
                    shouldFocusTriggerOnClose={false}
                    trigger={renderTrigger(
                      this.props.assignmentGroup,
                      ref => (this.optionsMenuTrigger = ref)
                    )}
                    onToggle={this.onToggle}
                    onDismiss={this.props.onMenuDismiss}
                  >
                    <Menu label={I18n.t('Sort by')} menuRef={this.bindSortByMenuContent}>
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

                    {this.props.showMessageStudentsWithObserversDialog && (
                      <Menu.Item
                        onSelect={() => this.showMessageStudentsWhoDialog(allStudents, courseId)}
                      >
                        <span data-menu-item-id="assignment-group-total-message-students-who">
                          {I18n.t('Message Students Who')}
                        </span>
                      </Menu.Item>
                    )}

                    {this.props.onApplyScoreToUngraded != null && <Menu.Separator />}

                    {this.props.onApplyScoreToUngraded != null && (
                      <Menu.Item
                        disabled={this.props.isRunningScoreToUngraded}
                        onSelect={this.props.onApplyScoreToUngraded}
                      >
                        {this.props.isRunningScoreToUngraded
                          ? I18n.t('Applying Score to Ungraded')
                          : I18n.t('Apply Score to Ungraded')}
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
