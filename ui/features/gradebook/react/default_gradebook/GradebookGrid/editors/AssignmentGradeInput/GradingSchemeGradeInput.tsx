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
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {TextInput} from '@instructure/ui-text-input'
import {IconArrowOpenDownLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {hasGradeChanged, parseTextValue} from '@canvas/grading/GradeInputHelper'

const I18n = createI18nScope('gradebook')

function formatGrade(
  // @ts-expect-error
  submission,
  // @ts-expect-error
  assignment,
  // @ts-expect-error
  gradingScheme,
  // @ts-expect-error
  pointsBasedGradingScheme,
  // @ts-expect-error
  scalingFactor,
  // @ts-expect-error
  pendingGradeInfo,
) {
  if (pendingGradeInfo) {
    return GradeFormatHelper.formatGradeInfo(pendingGradeInfo, {defaultValue: ''})
  }

  const formatOptions = {
    defaultValue: '',
    formatType: 'gradingScheme',
    gradingScheme,
    pointsBasedGradingScheme,
    pointsPossible: assignment.pointsPossible,
    scalingFactor,
    version: 'entered',
  }

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

// @ts-expect-error
function getGradeInfo(value, props) {
  return parseTextValue(value, {
    enterGradesAs: 'gradingScheme',
    gradingScheme: props.gradingScheme,
    pointsBasedGradingScheme: props.pointsBasedGradingScheme,
    pointsPossible: props.assignment.pointsPossible,
    scalingFactor: props.scalingFactor,
  })
}

export default class GradingSchemeInput extends Component {
  static propTypes = {
    assignment: shape({
      pointsPossible: number,
    }).isRequired,
    disabled: bool,
    gradingScheme: instanceOf(Array).isRequired,
    pointsBasedGradingScheme: bool,
    label: element.isRequired,
    menuContentRef: Menu.propTypes.menuRef,
    messages: arrayOf(
      shape({
        text: string.isRequired,
        type: string.isRequired,
      }),
    ).isRequired,
    onMenuDismiss: func,
    onMenuShow: func,
    pendingGradeInfo: shape({
      excused: bool.isRequired,
      grade: string,
      valid: bool.isRequired,
    }),
    scalingFactor: number,
    submission: shape({
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired,
    }).isRequired,
  }

  static defaultProps = {
    disabled: false,
    menuContentRef() {},
    onMenuDismiss() {},
    onMenuShow() {},
    pendingGradeInfo: null,
    pointsBasedGradingScheme: false,
    scalingFactor: null,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    // @ts-expect-error
    this.bindButton = ref => {
      // @ts-expect-error
      this.button = ref
    }
    // @ts-expect-error
    this.bindTextInput = ref => {
      // @ts-expect-error
      this.textInput = ref
    }

    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleSelect = this.handleSelect.bind(this)
    this.handleTextChange = this.handleTextChange.bind(this)
    this.handleToggle = this.handleToggle.bind(this)

    const {
      assignment,
      gradingScheme,
      pointsBasedGradingScheme,
      pendingGradeInfo,
      scalingFactor,
      submission,
    } = props

    const value = formatGrade(
      submission,
      assignment,
      gradingScheme,
      pointsBasedGradingScheme,
      scalingFactor,
      pendingGradeInfo,
    )

    this.state = {
      gradeInfo: pendingGradeInfo || getGradeInfo(submission.excused ? 'EX' : value, this.props),
      menuIsOpen: false,
      value: formatGrade(
        submission,
        assignment,
        gradingScheme,
        pointsBasedGradingScheme,
        scalingFactor,
        pendingGradeInfo,
      ),
    }
  }

  // @ts-expect-error
  UNSAFE_componentWillReceiveProps(nextProps) {
    // @ts-expect-error
    if (this.textInput !== document.activeElement) {
      const {
        assignment,
        gradingScheme,
        pointsBasedGradingScheme,
        pendingGradeInfo,
        scalingFactor,
        submission,
      } = nextProps

      const value = formatGrade(
        submission,
        assignment,
        gradingScheme,
        pointsBasedGradingScheme,
        scalingFactor,
        pendingGradeInfo,
      )

      this.setState({
        gradeInfo: pendingGradeInfo || getGradeInfo(submission.excused ? 'EX' : value, nextProps),
        value: formatGrade(
          submission,
          assignment,
          gradingScheme,
          pointsBasedGradingScheme,
          scalingFactor,
          pendingGradeInfo,
        ),
      })
    }
  }

  get gradeInfo() {
    // @ts-expect-error
    return this.state.gradeInfo
  }

  focus() {
    // @ts-expect-error
    if (this.button !== document.activeElement && !this.state.menuIsOpen) {
      // @ts-expect-error
      this.textInput.focus()
      // @ts-expect-error
      this.textInput.setSelectionRange(0, this.textInput.value.length)
    }
  }

  // @ts-expect-error
  handleKeyDown(event) {
    // Tab
    if (event.which === 9) {
      // @ts-expect-error
      if (!event.shiftKey && this.textInput === document.activeElement) {
        return false // prevent Grid behavior
        // @ts-expect-error
      } else if (event.shiftKey && this.button === document.activeElement) {
        return false // prevent Grid behavior
      }
    }

    // Enter
    // @ts-expect-error
    if (event.which === 13 && this.button === document.activeElement) {
      // the grading scheme menu opens/closes with Enter
      return false // prevent Grid behavior
    }

    return undefined
  }

  // @ts-expect-error
  handleSelect(event, value) {
    const gradeInfo = getGradeInfo(value, this.props)
    const formattedGrade = GradeFormatHelper.formatGradeInfo(gradeInfo)
    this.setState({gradeInfo, value: GradeFormatHelper.replaceDashWithMinus(formattedGrade)})
  }

  // @ts-expect-error
  handleTextChange(event) {
    this.setState({
      gradeInfo: getGradeInfo(event.target.value, this.props),
      value: event.target.value,
    })
  }

  // @ts-expect-error
  handleToggle(isOpen) {
    this.setState({menuIsOpen: isOpen}, () => {
      if (isOpen) {
        // @ts-expect-error
        this.props.onMenuShow()
      }
    })
  }

  hasGradeChanged() {
    // @ts-expect-error
    if (this.props.pendingGradeInfo) {
      // @ts-expect-error
      if (this.props.pendingGradeInfo.valid) {
        // the pending grade is currently being submitted
        // changes are not allowed
        return false
      }

      // the pending grade is invalid
      // return true only when the input value differs from the invalid grade
      // @ts-expect-error
      return this.state.value.trim() !== this.props.pendingGradeInfo.grade
    }
    // @ts-expect-error
    const {assignment, gradingScheme, pointsBasedGradingScheme, scalingFactor, submission} =
      this.props
    // @ts-expect-error
    const formattedGrade = formatGrade(
      submission,
      assignment,
      gradingScheme,
      pointsBasedGradingScheme,
      scalingFactor,
    )

    // @ts-expect-error
    if (formattedGrade === this.state.value.trim()) {
      return false
    }

    // @ts-expect-error
    const gradeInfo = getGradeInfo(this.state.value, this.props)
    // @ts-expect-error
    return hasGradeChanged(this.props.submission, gradeInfo, {
      enterGradesAs: 'gradingScheme',
      // @ts-expect-error
      gradingScheme: this.props.gradingScheme,
      // @ts-expect-error
      pointsPossible: this.props.assignment.pointsPossible,
    })
  }

  render() {
    return (
      <div className="HorizontalFlex">
        <TextInput
          // @ts-expect-error
          disabled={this.props.disabled}
          // @ts-expect-error
          inputRef={this.bindTextInput}
          // @ts-expect-error
          renderLabel={this.props.label}
          // @ts-expect-error
          messages={this.props.messages}
          onChange={this.handleTextChange}
          size="small"
          // @ts-expect-error
          value={this.state.value}
        />

        <div className="Grid__GradeCell__GradingSchemeMenu">
          <Menu
            // @ts-expect-error
            menuRef={this.props.menuContentRef}
            // @ts-expect-error
            onDismiss={this.props.onMenuDismiss}
            onToggle={this.handleToggle}
            onSelect={this.handleSelect}
            placement="bottom"
            trigger={
              <IconButton
                // @ts-expect-error
                elementRef={this.bindButton}
                // @ts-expect-error
                disabled={this.props.disabled}
                size="small"
                color="secondary"
                renderIcon={IconArrowOpenDownLine}
                screenReaderLabel={I18n.t('Open Grading Scheme menu')}
              />
            }
          >
            {/* @ts-expect-error */}
            {this.props.gradingScheme.map(([key]) => (
              <Menu.Item key={key} value={key}>
                {GradeFormatHelper.replaceDashWithMinus(key)}
              </Menu.Item>
            ))}
            <Menu.Item key="EX" value="EX">
              {GradeFormatHelper.excused()}
            </Menu.Item>
          </Menu>
        </div>
      </div>
    )
  }
}
