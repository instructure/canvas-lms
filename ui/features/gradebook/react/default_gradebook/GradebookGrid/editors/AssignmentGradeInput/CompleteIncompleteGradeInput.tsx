/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, {Component} from 'react'
import {bool, func, number, shape, string} from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {IconArrowOpenDownLine, IconCheckSolid, IconEndSolid} from '@instructure/ui-icons'

import {useScope as createI18nScope} from '@canvas/i18n'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {parseTextValue} from '@canvas/grading/GradeInputHelper'

const I18n = createI18nScope('gradebook')

// @ts-expect-error
function componentForGrade(grade, options = {}) {
  // @ts-expect-error
  const textSize = options.forMenu ? null : 'small'

  switch (grade) {
    case 'excused': {
      // @ts-expect-error
      return <Text size={textSize}>{GradeFormatHelper.excused()}</Text>
    }
    case 'complete': {
      return (
        <Text color="success">
          <IconCheckSolid title={I18n.t('Complete')} />
        </Text>
      )
    }
    case 'incomplete': {
      return (
        <Text>
          <IconEndSolid title={I18n.t('Incomplete')} />
        </Text>
      )
    }
    default: {
      // @ts-expect-error
      const ungradedValue = options.forMenu ? I18n.t('Ungraded') : '–'
      // @ts-expect-error
      return <Text size={textSize}>{ungradedValue}</Text>
    }
  }
}

// @ts-expect-error
function getGradeInfo(value, assignment) {
  return parseTextValue(value, {
    enterGradesAs: 'passFail',
    pointsPossible: assignment.pointsPossible,
  })
}

export default class CompleteIncompleteGradeInput extends Component {
  static propTypes = {
    assignment: shape({
      pointsPossible: number,
    }).isRequired,
    disabled: bool,
    menuContentRef: func,
    onMenuDismiss: Menu.propTypes.onDismiss,
    pendingGradeInfo: shape({
      excused: bool.isRequired,
      grade: string,
      valid: bool.isRequired,
    }),
    submission: shape({
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired,
    }).isRequired,
  }

  static defaultProps = {
    disabled: false,
    menuContentRef: null,
    onMenuDismiss() {},
    pendingGradeInfo: null,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)
    // @ts-expect-error
    this.bindButton = ref => {
      // @ts-expect-error
      this.button = ref
    }
    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleSelect = this.handleSelect.bind(this)
    // @ts-expect-error
    const grade = this.props.submission.excused ? 'EX' : this.props.submission.enteredGrade
    this.state = {
      // @ts-expect-error
      gradeInfo: this.props.pendingGradeInfo || getGradeInfo(grade, this.props.assignment),
    }
  }

  get gradeInfo() {
    // @ts-expect-error
    return this.state.gradeInfo
  }

  focus() {
    // @ts-expect-error
    if (this.button !== document.activeElement) {
      // @ts-expect-error
      this.button.focus()
    }
  }

  // @ts-expect-error
  handleKeyDown(event) {
    // Enter
    // @ts-expect-error
    if (event.which === 13 && this.button === document.activeElement) {
      // the complete/incomplete menu opens and closes with Enter
      return false // prevent Grid behavior
    }

    return undefined
  }

  // @ts-expect-error
  handleSelect(event, value) {
    // @ts-expect-error
    this.setState({gradeInfo: getGradeInfo(value, this.props.assignment)})
  }

  hasGradeChanged() {
    // @ts-expect-error
    const excusedChanged = this.state.gradeInfo.excused !== this.props.submission.excused
    // @ts-expect-error
    const gradeChanged = this.state.gradeInfo.grade !== this.props.submission.enteredGrade
    return excusedChanged || gradeChanged
  }

  render() {
    // @ts-expect-error
    const grade = this.state.gradeInfo.excused ? 'excused' : this.state.gradeInfo.grade
    const menuItems = [
      {status: 'complete', value: 'complete'},
      {status: 'incomplete', value: 'incomplete'},
      {status: 'ungraded', value: null},
      {status: 'excused', value: 'EX'},
    ]

    return (
      <div className="HorizontalFlex">
        <span className="Grid__GradeCell__CompleteIncompleteValue">{componentForGrade(grade)}</span>

        <div className="Grid__GradeCell__CompleteIncompleteMenu">
          <Menu
            // @ts-expect-error
            menuRef={this.props.menuContentRef}
            // @ts-expect-error
            onDismiss={this.props.onMenuDismiss}
            onSelect={this.handleSelect}
            placement="bottom"
            trigger={
              <IconButton
                // @ts-expect-error
                elementRef={this.bindButton}
                // @ts-expect-error
                disabled={this.props.disabled}
                size="small"
                renderIcon={IconArrowOpenDownLine}
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Open Complete/Incomplete menu')}
              />
            }
          >
            {menuItems.map(menuItem => (
              // @ts-expect-error
              <Menu.Item key={menuItem.status} value={menuItem.value}>
                {componentForGrade(menuItem.status, {forMenu: true})}
              </Menu.Item>
            ))}
          </Menu>
        </div>
      </div>
    )
  }
}
