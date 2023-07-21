/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useEffect, useMemo, useRef, useReducer} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Select} from '@instructure/ui-select'
import numberHelper from '@canvas/i18n/numberHelper'
import {FAILURE, STARTED, SUCCESS} from '../../grades/GradeActions'
import {arrayOf, bool, func, object, oneOf, shape, string} from 'prop-types'

const I18n = useI18nScope('assignment_grade_summary')

const NO_SELECTION = 'no-selection'
const NO_SELECTION_LABEL = '–'

const NO_SELECTION_GRADE = {
  gradeInfo: {},
  label: NO_SELECTION_LABEL,
  value: NO_SELECTION,
  disabled: true,
}

const INITIAL_STATE = {
  input: '',
  typed: '',
  expanded: false,
  highlightedId: null,
  selectedId: null,
  options: undefined,
  graderOptions: undefined,
  customGradeOption: undefined,
}

function reducer(prevState, action) {
  let state
  switch (action.event) {
    case 'new_props':
      return {
        ...prevState,
        input: action.input,
        selectedId: action.selectedId,
        graderOptions: action.graders,
        customGradeOption: action.custom,
        options: action.opts,
      }
    case 'show_options':
      return {...prevState, expanded: true}
    case 'hide_options':
      return {...prevState, expanded: false, highlightedId: null}
    case 'set_input':
      state = {
        ...prevState,
        input: action.input,
        typed: action.input,
        expanded: true,
        customGradeOption: action.custom,
      }
      state.options = action.custom
        ? [...prevState.graderOptions, action.custom]
        : prevState.graderOptions
      if (action.custom) state.highlightedId = action.custom.value
      return state
    case 'set_blur':
      return {
        ...prevState,
        typed: '',
        highlightedId: null,
        input: action.opt ? action.opt.label : NO_SELECTION_LABEL,
      }
    case 'set_highlight':
      state = {...prevState, highlightedId: action.id}
      if (action.type !== 'keydown') state.input = action.opt.label
      return state
    case 'set_select':
      return {
        ...prevState,
        selectedId: action.id,
        input: action.opt.label,
        typed: '',
        expanded: false,
      }
    default:
      throw new RangeError('bad event passed to dispatcher')
  }
}

function buildCustomGradeOption(gradeInfo, fmtr) {
  return {
    gradeInfo,
    label: `${fmtr(gradeInfo.score)} (${I18n.t('Custom')})`,
    value: gradeInfo.graderId,
  }
}
export default function GradeSelect(props) {
  const [state, dispatch] = useReducer(reducer, INITIAL_STATE)
  const originalSelectedOption = useRef(null)
  const inputRef = useRef(null)

  const locale = ENV?.LOCALE || navigator.language
  const numFormatter = useMemo(() => new Intl.NumberFormat(locale).format, [locale])

  useEffect(() => {
    const graders = []
    props.graders.forEach(grader => {
      const gradeInfo = props.grades[grader.graderId]
      if (gradeInfo) {
        graders.push({
          gradeInfo,
          label: `${numFormatter(gradeInfo.score)} (${grader.graderName})`,
          value: gradeInfo.graderId,
          disabled: !grader.graderSelectable,
        })
      }
    })
    const opts = [...graders]

    const custom = makeCustomGradeOption()
    if (custom) opts.push(custom)

    const selected = opts.find(opt => opt.gradeInfo.selected)
    originalSelectedOption.current = selected || null

    const dispatchData = {event: 'new_props', graders, custom, opts}
    dispatchData.input = selected ? selected.label : NO_SELECTION_LABEL
    dispatchData.selectedId = selected ? selected.value : null
    dispatch(dispatchData)
    // The dep array is a single element which is clearly a function (the resulting JSON string) of all
    // the deps, so it’s manifestly correct; unfortunately the linter can’t assume that just because a function
    // is called with all the necessary deps means that the return value is sensitive to any of them changing,
    // so it still complains. It doesn’t know what JSON.stringify does. JSON.stringify is used instead of just
    // listing the three dependencies because they are deep objects and React only compares shallowly.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify([props.graders, props.grades, props.finalGrader])])

  function filterOptions(text) {
    if (text.length === 0) return state.options
    const exactMatches = []
    const partialMatches = []
    const matchText = text.trim().toLowerCase()
    state.options.forEach(g => {
      if (g.value === NO_SELECTION) return
      const score = g.gradeInfo.score.toString()
      const label = g.label.toLowerCase()
      if (score === matchText && g.value !== state.customGradeOption.value) {
        exactMatches.push(g)
      } else if (score.includes(matchText) || label.includes(matchText)) {
        partialMatches.push(g)
      }
    })
    if (exactMatches.length + partialMatches.length === 0) return [NO_SELECTION_GRADE]
    return [...exactMatches, ...partialMatches]
  }

  function makeCustomGradeOption() {
    if (props.finalGrader) {
      const customGrade = props.grades[props.finalGrader.graderId]
      if (customGrade) return buildCustomGradeOption(customGrade, numFormatter)
    }
    return null
  }

  function getOptionById(id) {
    return state.options.find(o => o.value === id)
  }

  function performChange(selected) {
    if (!props.onSelect) return
    const original = originalSelectedOption.current

    if (
      state.customGradeOption &&
      selected.value === state.customGradeOption.value &&
      (!original || original.gradeInfo.score !== selected.gradeInfo.score)
    ) {
      props.onSelect(selected.gradeInfo)
      return
    }

    if (!original || original.value !== selected.value) {
      props.onSelect(selected.gradeInfo)
    }
  }

  function handleShowOptions(e) {
    dispatch({event: 'show_options'})
    props.onOpen?.(e)
  }

  function handleHideOptions(e) {
    dispatch({event: 'hide_options'})
    props.onClose?.(e)
  }

  function handleInputChange(e) {
    if (props.disabledCustomGrade) return
    const input = e.target.value.trimStart()
    let custom = makeCustomGradeOption()

    if (input.length > 0) {
      const score = numberHelper.parse(input.trimEnd())

      if (!Number.isNaN(score)) {
        custom = buildCustomGradeOption(
          {
            ...state.customGradeOption?.gradeInfo,
            graderId: props.finalGrader.graderId,
            score,
            studentId: props.studentId,
          },
          numFormatter
        )
      }
    }

    dispatch({event: 'set_input', input, custom})
  }

  function handleFocus() {
    // selecting all text when the input widget is focussed makes it easier for the user to just start typing
    inputRef.current?.select()
  }

  function handleBlur() {
    const opt = state.selectedId && getOptionById(state.selectedId)
    dispatch({event: 'set_blur', opt})
  }

  function handleHighlight({type}, {id}) {
    const opt = getOptionById(id)
    if (!opt) return
    dispatch({event: 'set_highlight', id, opt, type})
  }

  function handleSelect(e, {id}) {
    const opt = getOptionById(id)
    if (!opt) return
    dispatch({event: 'set_select', id, opt})
    performChange(opt)
  }

  function renderOptions() {
    if (!state.options) return []
    return filterOptions(state.typed).map(opt => (
      <Select.Option
        isDisabled={opt.disabled}
        isHighlighted={opt.value === state.highlightedId}
        isSelected={opt.value === state.selectedId}
        key={opt.value}
        id={opt.value}
        value={opt.value}
      >
        {opt.label}
      </Select.Option>
    ))
  }

  const readOnly = !props.onSelect || props.selectProvisionalGradeStatus === STARTED

  return (
    <Select
      renderLabel={
        <ScreenReaderContent>
          {I18n.t('Grade for %{studentName}', {studentName: props.studentName})}
        </ScreenReaderContent>
      }
      inputRef={ref => {
        inputRef.current = ref
      }}
      interaction={readOnly ? 'disabled' : 'enabled'}
      inputValue={state.input}
      data-testid="moderated-graded-select"
      onFocus={handleFocus}
      onBlur={handleBlur}
      onInputChange={handleInputChange}
      isShowingOptions={state.expanded}
      onRequestShowOptions={handleShowOptions}
      onRequestHideOptions={handleHideOptions}
      onRequestHighlightOption={handleHighlight}
      onRequestSelectOption={handleSelect}
    >
      {renderOptions()}
    </Select>
  )
}

GradeSelect.propTypes = {
  disabledCustomGrade: bool.isRequired,
  finalGrader: shape({
    graderId: string.isRequired,
  }),
  graders: arrayOf(
    shape({
      graderName: string,
      graderId: string.isRequired,
    })
  ).isRequired,
  grades: object.isRequired,
  onClose: func,
  onOpen: func,
  onSelect: func,
  selectProvisionalGradeStatus: oneOf([FAILURE, STARTED, SUCCESS]),
  studentId: string.isRequired,
  studentName: string.isRequired,
}

GradeSelect.defaultProps = {
  finalGrader: null,
  onClose: null,
  onOpen: null,
  onSelect: null,
  selectProvisionalGradeStatus: null,
}

export {NO_SELECTION_LABEL}
