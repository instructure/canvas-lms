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
import {arrayOf, bool, func, oneOf, shape, string} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import I18n from 'i18n!assignment_grade_summary'

import numberHelper from '@canvas/i18n/numberHelper'
import {FAILURE, STARTED, SUCCESS} from '../../grades/GradeActions'

const NO_SELECTION = 'no-selection'
const NO_SELECTION_LABEL = '–'

function filterOptions(options, filterText) {
  const exactMatches = []
  const partialMatches = []
  const matchText = filterText.toLowerCase()

  options.forEach(option => {
    const score = String(option.gradeInfo.score)
    const label = option.label.toLowerCase()

    if (score === matchText) {
      exactMatches.push(option)
    } else if (score.includes(matchText)) {
      partialMatches.push(option)
    } else if (label.includes(matchText)) {
      partialMatches.push(option)
    }
  })

  return exactMatches.concat(partialMatches)
}

function optionsForGraders(graders, grades) {
  const options = []
  for (let i = 0; i < graders.length; i++) {
    const grader = graders[i]
    const gradeInfo = grades[grader.graderId]
    if (gradeInfo) {
      options.push({
        gradeInfo,
        label: `${I18n.n(gradeInfo.score)} (${grader.graderName})`,
        value: gradeInfo.graderId,
        disabled: !grader.graderSelectable
      })
    }
  }
  return options
}

function buildCustomGradeOption(gradeInfo) {
  return {
    gradeInfo,
    label: `${I18n.n(gradeInfo.score)} (${I18n.t('Custom')})`,
    value: gradeInfo.graderId
  }
}

function customGradeOptionFromProps({finalGrader, grades}) {
  if (finalGrader) {
    const customGrade = grades[finalGrader.graderId]
    if (customGrade) {
      return buildCustomGradeOption(customGrade)
    }
  }
  return null
}

// for the future author, the behavior of this widget is intended to double as
// both a select menu and a text input widget. The text input provided by the
// user is also intended to double as both a filter for the menu options as well
// as a value for a custom/provisional grade that gets morphed into a menu
// option if they choose it (either by selecting the menu option or by pressing
// RETURN).
//
// While SimpleSelect takes us a long way, we still need to tune it. That's why
// you'll see me making some imperative calls to its internal APIs, it's not
// because I necessarily hate you. This was still a lot cheaper than building
// off of the underlying Select component, which takes a ton of work.
class TypableSimpleSelect extends SimpleSelect {
  componentDidUpdate(prevProps) {
    if (this.props.value !== prevProps.value) {
      const option = this.getOption('value', this.props.value)

      if (option) {
        this.setState({
          inputValue: option.props.children,
          selectedOptionId: option.props.id
        })
      }
      else { // let the text the user is typing go through
        this.setState({ selectedOptionId: '' })
      }
    }
  }
};

export default class GradeSelect extends Component {
  static propTypes = {
    disabledCustomGrade: bool.isRequired,
    finalGrader: shape({
      graderId: string.isRequired
    }),
    /* eslint-disable-next-line react/no-unused-prop-types */
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired
      })
    ).isRequired,
    grades: shape({}).isRequired,
    onClose: func,
    onOpen: func,
    onSelect: func,
    selectProvisionalGradeStatus: oneOf([FAILURE, STARTED, SUCCESS]),
    studentId: string.isRequired,
    studentName: string.isRequired
  }

  static defaultProps = {
    finalGrader: null,
    onClose() {},
    onOpen() {},
    onSelect() {},
    selectProvisionalGradeStatus: null
  }

  constructor(props) {
    super(props)

    this.bindMenu = ref => {
      if (ref) {
        this.$input = ref
        const menuId = ref.getAttribute('aria-controls')
        this.$menu = document.getElementById(menuId)
      } else {
        this.$menu = null
      }
    }
    this.bindSelect = ref => {
      this.select = ref
    }

    this.handleChange = this.handleChange.bind(this)
    this.handleClose = this.handleClose.bind(this)
    this.handleInputChange = this.handleInputChange.bind(this)
    this.filterAndBuildCustomOption = this.filterAndBuildCustomOption.bind(this)
    this.discardCustomOption = this.discardCustomOption.bind(this)
    this.acceptCustomOption = this.acceptCustomOption.bind(this)

    this.state = this.constructor.createStateFromProps(props)
  }

  static createStateFromProps(props) {
    const graderOptions = optionsForGraders(props.graders, props.grades)
    const options = [...graderOptions]

    const customGradeOption = customGradeOptionFromProps(props)

    if (customGradeOption) {
      options.push(customGradeOption)

      if (customGradeOption.gradeInfo.selected) {
        selectedOption = customGradeOption
      }
    }

    var selectedOption = options.find(option => option.gradeInfo.selected)
    if (!selectedOption) {
      selectedOption = {gradeInfo: {}, label: NO_SELECTION_LABEL, value: NO_SELECTION}
      options.unshift(selectedOption)
    }

    return {
      customGradeOption,
      graderOptions,
      options,
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState(this.constructor.createStateFromProps(nextProps))
  }

  shouldComponentUpdate(nextProps, nextState) {
    return (
      Object.keys(nextProps).some(key => this.props[key] !== nextProps[key]) ||
      Object.keys(nextState).some(key => this.state[key] !== nextState[key])
    )
  }

  handleChange(_event, selectedOption) {
    if (
      this.props.onSelect == null ||
      selectedOption == null ||
      selectedOption.value === NO_SELECTION
    ) {
      return
    }

    const options = [...this.state.graderOptions]
    if (this.state.customGradeOption) {
      options.push(this.state.customGradeOption)
    }

    this.setState({options}, () => {
      const optionMatch = this.state.options.find(option => option.value === selectedOption.value)
      if (!optionMatch.gradeInfo.selected) {
        this.props.onSelect(optionMatch.gradeInfo)
      } else {
        const originalGrade = this.props.grades[optionMatch.value]
        if (optionMatch.gradeInfo.score !== originalGrade.score) {
          this.props.onSelect(optionMatch.gradeInfo)
        }
      }
    })
  }

  handleClose() {
    if (
      this.$input === document.activeElement ||
      (this.$menu && this.$menu.contains(document.activeElement))
    ) {
      this.select.focus()
    }

    if (this.props.onClose) {
      this.props.onClose()
    }
  }

  handleInputChange(event, value) {
    if (this.select && this.canInputCustomGrades()) {
      this.select.setState/*[1]*/({ inputValue: event.target.value }, () => {
        this.filterAndBuildCustomOption()
      })
      // [1] yuck yes, a proper solution would be built on top of the underlying
      //     Select and not SimpleSelect with proper time investment
    }
  }

  filterAndBuildCustomOption() {
    const input = this.getInputBuffer()

    if (!input) {
      return this.setState(this.constructor.createStateFromProps(this.props))
    }

    const options = filterOptions(this.state.graderOptions, input)
    const score = numberHelper.parse(input)

    let customGradeOption = customGradeOptionFromProps(this.props)

    // both filter and a custom grade entry
    if (!Number.isNaN(score)) {
      customGradeOption = buildCustomGradeOption({
        ...customGradeOption?.gradeInfo,
        graderId: this.props.finalGrader.graderId,
        score,
        studentId: this.props.studentId
      })
    }

    this.setState({
      customGradeOption,
      options: customGradeOption ? options.concat([customGradeOption]) : options
    })
  }

  discardCustomOption() {
    return this.setState(this.constructor.createStateFromProps(this.props))
  }

  getInputBuffer() {
    const input = this.select && this.select.state.inputValue.trim()

    if (input && input.length && input !== NO_SELECTION_LABEL) {
      return input
    }
    else {
      return null
    }
  }

  acceptCustomOption() {
    // selecting all the text when the input widget is focused makes it easier
    // for the user to just type in the provisional grade (or filter), because
    // the normal Home/End behavior is hijacked by the InstUI select components
    // and the fact that back-spacing can also produce strange results when you
    // filter down to 1 option.....
    this.$input.select()
  }

  canInputCustomGrades() {
    return !this.props.disabledCustomGrade && this.props.onSelect
  }

  getSelectedOption() {
    return this.state.options.find(x => x.gradeInfo.selected)
  }

  render() {
    const readOnly = !this.props.onSelect

    return (
      <TypableSimpleSelect
        aria-readonly={readOnly || this.props.selectProvisionalGradeStatus === STARTED}
        editable={!(this.props.disabledCustomGrade || readOnly)}
        inputRef={this.bindMenu}
        renderLabel={
          <ScreenReaderContent>
            {I18n.t('Grade for %{studentName}', {studentName: this.props.studentName})}
          </ScreenReaderContent>
        }
        onChange={this.handleChange}
        onInputChange={this.handleInputChange}
        onFocus={this.acceptCustomOption}
        onBlur={this.discardCustomOption}
        onShowOptions={this.props.onOpen}
        onHideOptions={this.handleClose}
        ref={this.bindSelect}
        value={this.getSelectedOption()?.value || null}
      >
        {this.state.options.map(gradeOption => (
          <SimpleSelect.Option
            isDisabled={gradeOption.disabled}
            key={gradeOption.value}
            id={gradeOption.value}
            value={gradeOption.value}
          >
            {gradeOption.label}
          </SimpleSelect.Option>
        ))}
      </TypableSimpleSelect>
    )
  }
}

export { NO_SELECTION_LABEL }
