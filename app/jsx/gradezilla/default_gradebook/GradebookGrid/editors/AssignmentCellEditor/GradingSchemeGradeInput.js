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
import {arrayOf, bool, element, func, instanceOf, number, shape, string} from 'prop-types'
import Button from '@instructure/ui-core/lib/components/Button'
import {MenuItem} from '@instructure/ui-core/lib/components/Menu'
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu'
import TextInput from '@instructure/ui-core/lib/components/TextInput'
import IconArrowOpenDownLine from 'instructure-icons/lib/Line/IconArrowOpenDownLine'
import I18n from 'i18n!gradebook'
import GradeFormatHelper from '../../../../../gradebook/shared/helpers/GradeFormatHelper'
import {hasGradeChanged, parseTextValue} from '../../../../../grading/helpers/GradeInputHelper'

function formatGrade(submission, assignment, gradingScheme, pendingGradeInfo) {
  if (pendingGradeInfo) {
    return GradeFormatHelper.formatGradeInfo(pendingGradeInfo, {defaultValue: ''})
  }

  const formatOptions = {
    defaultValue: '',
    formatType: 'gradingScheme',
    gradingScheme,
    pointsPossible: assignment.pointsPossible,
    version: 'entered'
  }

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

function getGradeInfo(value, props) {
  return parseTextValue(value, {
    enterGradesAs: 'gradingScheme',
    gradingScheme: props.gradingScheme,
    pointsPossible: props.assignment.pointsPossible
  })
}

export default class GradingSchemeInput extends Component {
  static propTypes = {
    assignment: shape({
      pointsPossible: number
    }).isRequired,
    disabled: bool,
    gradingScheme: instanceOf(Array).isRequired,
    label: element.isRequired,
    menuContentRef: func,
    messages: arrayOf(
      shape({
        text: string.isRequired,
        type: string.isRequired
      })
    ).isRequired,
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
    this.bindTextInput = ref => {
      this.textInput = ref
    }

    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleSelect = this.handleSelect.bind(this)
    this.handleTextChange = this.handleTextChange.bind(this)
    this.handleToggle = this.handleToggle.bind(this)

    const {assignment, gradingScheme, pendingGradeInfo, submission} = props
    const value = formatGrade(submission, assignment, gradingScheme, pendingGradeInfo)

    this.state = {
      gradeInfo: pendingGradeInfo || getGradeInfo(submission.excused ? 'EX' : value, this.props),
      menuIsOpen: false,
      value: formatGrade(submission, assignment, gradingScheme, pendingGradeInfo)
    }
  }

  componentWillReceiveProps(nextProps) {
    if (this.textInput !== document.activeElement) {
      const {assignment, gradingScheme, pendingGradeInfo, submission} = nextProps
      const value = formatGrade(submission, assignment, gradingScheme, pendingGradeInfo)

      this.setState({
        gradeInfo: pendingGradeInfo || getGradeInfo(submission.excused ? 'EX' : value, nextProps),
        value: formatGrade(submission, assignment, gradingScheme, pendingGradeInfo)
      })
    }
  }

  get gradeInfo() {
    return this.state.gradeInfo
  }

  focus() {
    if (this.button !== document.activeElement && !this.state.menuIsOpen) {
      this.textInput.focus()
      this.textInput.setSelectionRange(0, this.textInput.value.length)
    }
  }

  handleKeyDown(event) {
    // Tab
    if (event.which === 9) {
      if (!event.shiftKey && this.textInput === document.activeElement) {
        return false // prevent Grid behavior
      } else if (event.shiftKey && this.button === document.activeElement) {
        return false // prevent Grid behavior
      }
    }

    // Enter
    if (event.which === 13 && this.button === document.activeElement) {
      // the grading scheme menu opens/closes with Enter
      return false // prevent Grid behavior
    }

    return undefined
  }

  handleSelect(event, value) {
    const gradeInfo = getGradeInfo(value, this.props)
    const formattedGrade = GradeFormatHelper.formatGradeInfo(gradeInfo)
    this.setState({gradeInfo, value: formattedGrade})
  }

  handleTextChange(event) {
    this.setState({
      gradeInfo: getGradeInfo(event.target.value, this.props),
      value: event.target.value
    })
  }

  handleToggle(isOpen) {
    this.setState({menuIsOpen: isOpen})
  }

  hasGradeChanged() {
    if (this.props.pendingGradeInfo) {
      if (this.props.pendingGradeInfo.valid) {
        // the pending grade is currently being submitted
        // changes are not allowed
        return false
      }

      // the pending grade is invalid
      // return true only when the input value differs from the invalid grade
      return this.state.value.trim() !== this.props.pendingGradeInfo.grade
    }

    const {assignment, gradingScheme, submission} = this.props
    const formattedGrade = formatGrade(submission, assignment, gradingScheme)

    if (formattedGrade === this.state.value.trim()) {
      return false
    }

    const gradeInfo = getGradeInfo(this.state.value, this.props)
    return hasGradeChanged(this.props.submission, gradeInfo, {
      enterGradesAs: 'gradingScheme',
      gradingScheme: this.props.gradingScheme,
      pointsPossible: this.props.assignment.pointsPossible
    })
  }

  render() {
    return (
      <div className="HorizontalFlex">
        <TextInput
          disabled={this.props.disabled}
          inputRef={this.bindTextInput}
          label={this.props.label}
          messages={this.props.messages}
          onChange={this.handleTextChange}
          size="small"
          value={this.state.value}
        />

        <div className="Grid__AssignmentRowCell__GradingSchemeMenu">
          <PopoverMenu
            contentRef={this.props.menuContentRef}
            onClose={this.props.onMenuClose}
            onToggle={this.handleToggle}
            onSelect={this.handleSelect}
            placement="bottom"
            trigger={
              <Button buttonRef={this.bindButton} disabled={this.props.disabled} size="small" variant="icon">
                <IconArrowOpenDownLine title={I18n.t('Open Grading Scheme menu')} />
              </Button>
            }
          >
            {this.props.gradingScheme.map(([key]) => (
              <MenuItem key={key} value={key}>
                {key}
              </MenuItem>
            ))}

            <MenuItem key="EX" value="EX">
              {GradeFormatHelper.excused()}
            </MenuItem>
          </PopoverMenu>
        </div>
      </div>
    )
  }
}
