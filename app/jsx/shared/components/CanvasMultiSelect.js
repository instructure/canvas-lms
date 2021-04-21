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
import I18n from 'i18n!app_shared_components'
import keycode from 'keycode'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'
import {func, string, node, arrayOf, oneOfType, bool} from 'prop-types'
import {matchComponentTypes} from '@instructure/ui-react-utils'
import {compact, uniqueId} from 'lodash'
import {Alert} from '@instructure/ui-alerts'

const CanvasMultiSelectOption = () => <div />

CanvasMultiSelectOption.propTypes = {
  id: string.isRequired, // eslint-disable-line react/no-unused-prop-types
  value: string.isRequired // eslint-disable-line react/no-unused-prop-types
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
        label: n.props.children
      })),
    [children]
  )

  const allChildIds = childProps.map(x => x.id)
  const [filteredOptionIds, setFilteredOptionIds] = useState(allChildIds)

  function getChildById(id) {
    return childProps.find(c => c.id === id)
  }

  function renderChildren() {
    function renderOption(child) {
      // eslint-disable-next-line no-shadow
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
          filteredOptionIds.includes(child.props.id) &&
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
            dismissible
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

  function onInputChange(e) {
    const {value} = e.target
    const matcher = new RegExp('^' + value.trim(), 'i')
    const filtered = childProps.filter(x => x.label.match(matcher))
    let message =
      // if number of options has changed, announce the new total.
      filtered.length !== filteredOptionIds.length
        ? I18n.t(
            {
              one: 'One option available.',
              other: '%{count} options available.'
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
    if (filteredOptionIds.length === 1) {
      const option = getChildById(filteredOptionIds[0])
      setAnnouncement(I18n.t('%{label} selected. List collapsed.', {label: option.label}))
      onChange([...selectedOptionIds, filteredOptionIds[0]])
    }
    setFilteredOptionIds(allChildIds)
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
    setFilteredOptionIds(allChildIds)
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
    renderBeforeInput: selectedOptionIds.length > 0 ? renderTags() : null
  }

  return (
    <>
      <Select {...selectProps} {...otherProps}>
        {renderChildren()}
      </Select>
      {announcement && (
        <Alert liveRegion={liveRegion} liveRegionPoliteness="assertive" screenReaderOnly>
          {announcement}
        </Alert>
      )}
    </>
  )
}

CanvasMultiSelect.propTypes = {
  id: string,
  disabled: bool,
  label: oneOfType([node, func]).isRequired,
  onChange: func.isRequired,
  children: node,
  selectedOptionIds: arrayOf(string),
  noOptionsLabel: string
}

CanvasMultiSelect.defaultProps = {
  noOptionsLabel: '---',
  selectedOptionIds: [],
  disabled: false
}

CanvasMultiSelect.Option = CanvasMultiSelectOption

export default CanvasMultiSelect
