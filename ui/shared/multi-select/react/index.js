/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useState, useRef, useMemo} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import keycode from 'keycode'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'
import {func, string, node, arrayOf, oneOfType, bool} from 'prop-types'
import {matchComponentTypes} from '@instructure/ui-react-utils'
import {compact, uniqueId} from 'lodash'
import {Alert} from '@instructure/ui-alerts'

const I18n = useI18nScope('app_shared_components')

const CanvasMultiSelectOption = () => <div />

CanvasMultiSelectOption.propTypes = {
  id: string.isRequired, // eslint-disable-line react/no-unused-prop-types
  value: string.isRequired, // eslint-disable-line react/no-unused-prop-types
}

function alwaysArray(scalarOrArray) {
  if (!scalarOrArray) return null
  return Array.isArray(scalarOrArray) ? scalarOrArray : [scalarOrArray]
}

function liveRegion() {
  return document.getElementById('flash_screenreader_holder')
}

const NO_OPTIONS_OPTION_ID = '__no_option-'

function CanvasMultiSelect(props) {
  const {
    id: selectId,
    label: renderLabel,
    onChange,
    children,
    selectedOptionIds,
    noOptionsLabel,
    disabled,
    customRenderBeforeInput,
    customMatcher,
    ...otherProps
  } = props

  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  const [announcement, setAnnouncement] = useState(null)
  const inputRef = useRef(null)
  const noOptionId = useRef(uniqueId(NO_OPTIONS_OPTION_ID))

  const childProps = useMemo(
    () =>
      React.Children.map(children, n => ({
        id: n.props.id,
        value: n.props.value,
        label: n.props.children,
      })),
    [children]
  )

  const [filteredOptionIds, setFilteredOptionIds] = useState(null)

  function getChildById(id) {
    return childProps.find(c => c.id === id)
  }

  function renderChildren() {
    function renderOption(child) {
      const {id, children, ...optionProps} = child.props
      return (
        <Select.Option
          id={id}
          key={child.key || id || uniqueId('multi-select-')}
          isHighlighted={id === highlightedOptionId}
          {...optionProps}
        >
          {children}
        </Select.Option>
      )
    }

    function renderNoOptionsOption() {
      return (
        <Select.Option id={noOptionId.current} isHighlighted={false} isSelected={false}>
          {noOptionsLabel}
        </Select.Option>
      )
    }

    const filteredChildren = compact(
      alwaysArray(children).map(child => {
        if (
          matchComponentTypes(child, [CanvasMultiSelectOption]) &&
          (!filteredOptionIds || filteredOptionIds.includes(child.props.id)) &&
          !selectedOptionIds.includes(child.props.id)
        ) {
          return renderOption(child)
        }
        return null
      })
    )

    return filteredChildren.length === 0 ? renderNoOptionsOption() : filteredChildren
  }

  function dismissTag(e, id) {
    e.stopPropagation()
    e.preventDefault()
    onChange(selectedOptionIds.filter(x => x !== id))
  }

  function renderTags() {
    const options = alwaysArray(children)
    if (!options) return null

    return compact(
      selectedOptionIds.map(id => {
        const opt = options.find(c => c.props.id === id)
        if (!opt) return null
        const tagText = opt.props.children || opt.props.label
        return (
          <Tag
            dismissible={true}
            key={opt.key}
            text={tagText}
            title={I18n.t('Remove %{label}', {label: tagText})}
            margin="0 xxx-small"
            onClick={e => dismissTag(e, id)}
          />
        )
      })
    )
  }

  function contentBeforeInput() {
    const tags = selectedOptionIds.length > 0 ? renderTags() : null
    return customRenderBeforeInput ? customRenderBeforeInput(tags) : tags
  }

  function onInputChange(e) {
    const {value} = e.target
    const defaultMatcher = (option, term) => option.label.match(new RegExp(`^${term}`, 'i'))
    const matcher = customMatcher || defaultMatcher
    const filtered = childProps.filter(child => matcher(child, value.trim()))
    let message =
      // if number of options has changed, announce the new total.
      filtered.length !== filteredOptionIds?.length
        ? I18n.t(
            {
              one: 'One option available.',
              other: '%{count} options available.',
            },
            {count: filtered.length}
          )
        : null
    if (message && filtered.length > 0 && highlightedOptionId !== filtered[0].id) {
      message = getChildById(filtered[0].id).label + '. ' + message
    }
    setInputValue(value)
    setFilteredOptionIds(filtered.map(f => f.id))
    if (filtered.length > 0) setHighlightedOptionId(filtered[0].id)
    setIsShowingOptions(true)
    setAnnouncement(message)
  }

  function onRequestShowOptions() {
    setIsShowingOptions(true)
  }

  function onRequestHideOptions() {
    setIsShowingOptions(false)
    if (!highlightedOptionId) return
    setInputValue('')
    if (filteredOptionIds?.length === 1) {
      const option = getChildById(filteredOptionIds[0])
      setAnnouncement(I18n.t('%{label} selected. List collapsed.', {label: option.label}))
      onChange([...selectedOptionIds, filteredOptionIds[0]])
    }
    setFilteredOptionIds(null)
  }

  function onRequestHighlightOption(e, {id}) {
    e.persist()
    const option = getChildById(id)
    if (typeof option === 'undefined') return
    if (e.type === 'keydown') setInputValue(option.label)
    setHighlightedOptionId(id)
    setAnnouncement(option.label)
  }

  function onRequestSelectOption(_e, {id}) {
    const option = getChildById(id)
    setInputValue('')
    setFilteredOptionIds(null)
    setIsShowingOptions(false)
    if (typeof option === 'undefined') return
    setAnnouncement(I18n.t('%{label} selected. List collapsed.', {label: option.label}))
    onChange([...selectedOptionIds, id])
  }

  // if backspace is pressed and there's no input to backspace over, remove the
  // last selected option if there is one
  function onKeyDown(e) {
    if (
      e.keyCode === keycode.codes.backspace &&
      inputValue.length === 0 &&
      selectedOptionIds.length > 0
    ) {
      const option = getChildById(selectedOptionIds.slice(-1)[0])
      setAnnouncement(I18n.t('%{label} removed.', {label: option.label}))
      onChange(selectedOptionIds.slice(0, -1))
    }
  }

  function onBlur() {
    setHighlightedOptionId(null)
  }

  const selectProps = {
    id: selectId,
    disabled,
    renderLabel,
    inputValue,
    inputRef: ref => {
      inputRef.current = ref
    },
    onInputChange,
    onRequestShowOptions,
    onRequestHideOptions,
    isShowingOptions,
    onRequestHighlightOption,
    onRequestSelectOption,
    onKeyDown,
    onBlur,
    assistiveText: I18n.t('Type or use arrow keys to navigate. Multiple selections are allowed.'),
    renderBeforeInput: contentBeforeInput(),
  }

  return (
    <>
      <Select {...selectProps} {...otherProps}>
        {renderChildren()}
      </Select>
      {announcement && (
        <Alert liveRegion={liveRegion} liveRegionPoliteness="assertive" screenReaderOnly={true}>
          {announcement}
        </Alert>
      )}
    </>
  )
}

CanvasMultiSelect.propTypes = {
  id: string,
  customMatcher: func,
  customRenderBeforeInput: func,
  disabled: bool,
  label: oneOfType([node, func]).isRequired,
  onChange: func.isRequired,
  placeholder: string,
  children: node.isRequired,
  selectedOptionIds: arrayOf(string).isRequired,
  noOptionsLabel: string,
}

CanvasMultiSelect.defaultProps = {
  customMatcher: null,
  customRenderBeforeInput: null,
  noOptionsLabel: '---',
  selectedOptionIds: [],
  disabled: false,
}

CanvasMultiSelect.Option = CanvasMultiSelectOption

export default CanvasMultiSelect
