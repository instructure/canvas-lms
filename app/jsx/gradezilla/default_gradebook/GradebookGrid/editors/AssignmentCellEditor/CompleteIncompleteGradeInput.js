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
import Button from '@instructure/ui-core/lib/components/Button'
import {MenuItem} from '@instructure/ui-core/lib/components/Menu'
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu'
import Text from '@instructure/ui-core/lib/components/Text'
import IconArrowOpenDownLine from 'instructure-icons/lib/Line/IconArrowOpenDownLine'
import IconCheckSolid from 'instructure-icons/lib/Solid/IconCheckSolid'
import IconXSolid from 'instructure-icons/lib/Solid/IconXSolid'
import I18n from 'i18n!gradebook'
import GradeFormatHelper from '../../../../../gradebook/shared/helpers/GradeFormatHelper'
import {parseTextValue} from '../../../../../grading/helpers/GradeInputHelper'

function componentForGrade(grade, options = {}) {
  const textSize = options.forMenu ? null : 'small'

  switch (grade) {
    case 'excused': {
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
          <IconXSolid title={I18n.t('Incomplete')} />
        </Text>
      )
    }
    default: {
      const ungradedValue = options.forMenu ? I18n.t('Ungraded') : '–'
      return <Text size={textSize}>{ungradedValue}</Text>
    }
  }
}

function getGradeInfo(value, props) {
  return parseTextValue(value, {
    enterGradesAs: 'passFail',
    pointsPossible: props.assignment.pointsPossible
  })
}

export default class CompleteIncompleteGradeInput extends Component {
  static propTypes = {
    assignment: shape({
      pointsPossible: number
    }).isRequired,
    disabled: bool,
    menuContentRef: func,
    onMenuClose: func,
    pendingGradeInfo: shape({
      excused: bool.isRequired,
      grade: string,
      valid: bool.isRequired
    }),
    submission: shape({
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired
    }).isRequired
  }

  static defaultProps = {
    disabled: false,
    menuContentRef: null,
    onMenuClose: null,
    pendingGradeInfo: null
  }

  constructor(props) {
    super(props)
    this.bindButton = ref => {
      this.button = ref
    }
    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleSelect = this.handleSelect.bind(this)
    const grade = this.props.submission.excused ? 'EX' : this.props.submission.enteredGrade
    this.state = {
      gradeInfo: this.props.pendingGradeInfo || getGradeInfo(grade, this.props)
    }
  }

  get gradeInfo() {
    return this.state.gradeInfo
  }

  focus() {
    if (this.button !== document.activeElement) {
      this.button.focus()
    }
  }

  handleKeyDown(event) {
    // Enter
    if (event.which === 13 && this.button === document.activeElement) {
      // the complete/incomplete menu opens and closes with Enter
      return false // prevent Grid behavior
    }

    return undefined
  }

  handleSelect(event, value) {
    this.setState({gradeInfo: getGradeInfo(value, this.props)})
  }

  hasGradeChanged() {
    const excusedChanged = this.state.gradeInfo.excused !== this.props.submission.excused
    const gradeChanged = this.state.gradeInfo.grade !== this.props.submission.enteredGrade
    return excusedChanged || gradeChanged
  }

  render() {
    const grade = this.state.gradeInfo.excused ? 'excused' : this.state.gradeInfo.grade
    const menuItems = [
      {status: 'complete', value: 'complete'},
      {status: 'incomplete', value: 'incomplete'},
      {status: 'ungraded', value: null},
      {status: 'excused', value: 'EX'}
    ]

    return (
      <div className="HorizontalFlex">
        <span className="Grid__AssignmentRowCell__CompleteIncompleteValue">
          {componentForGrade(grade)}
        </span>

        <div className="Grid__AssignmentRowCell__CompleteIncompleteMenu">
          <PopoverMenu
            contentRef={this.props.menuContentRef}
            onClose={this.props.onMenuClose}
            onSelect={this.handleSelect}
            placement="bottom"
            trigger={
              <Button
                buttonRef={this.bindButton}
                disabled={this.props.disabled}
                size="small"
                variant="icon"
              >
                <IconArrowOpenDownLine title={I18n.t('Open Complete/Incomplete menu')} />
              </Button>
            }
          >
            {menuItems.map(menuItem => (
              <MenuItem key={menuItem.status} value={menuItem.value}>
                {componentForGrade(menuItem.status, {forMenu: true})}
              </MenuItem>
            ))}
          </PopoverMenu>
        </div>
      </div>
    )
  }
}
