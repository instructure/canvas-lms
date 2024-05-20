/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {Children, useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Select} from '@instructure/ui-select'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {uid} from '@instructure/uid'
import {string} from 'prop-types'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {createAnalyticPropsGenerator} from './util/analytics'
import {MODULE_NAME} from './types'

const I18n = useI18nScope('managed_course_selector')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

const NO_OPTIONS_OPTION_ID = '___noOptionsOption__'

// regular expression special character escaper
const reEscapeMatcher = /(\^|\$|\|\.|\*|\+|\?|\(|\)|\[|\]|\{|\}|\||\\)/g
const reEscape = (str: string) => str.replace(reEscapeMatcher, '\\$1')

const SearchableSelectOption = () => <div />
/* eslint-disable react/no-unused-prop-types */
SearchableSelectOption.propTypes = {
  id: string,
  value: string,
  children: string,
  label: string,
}
/* eslint-enable react/no-unused-prop-types */
SearchableSelectOption.displayName = 'Option'

interface Props {
  id: string
  isLoading: boolean
  value: string
  onChange: Function
  label: string
  placeholder: string
  noResultsLabel: string
  noSearchMatchLabel: string
  children: any
}

function flattenOptions(nodes: any) {
  const options: any[][] = []

  Children.forEach(nodes, n => {
    if (Array.isArray(n)) {
      options.push(flattenOptions(n))
    } else if (n?.type?.displayName === 'Option') {
      options.push(n)
    }
  })
  return options.flat()
}

export default function RoleSearchSelect(props: Props) {
  const {id: selectId, value, children, isLoading, onChange, label} = props
  const noResultsLabel = props.noResultsLabel || I18n.t('No results')
  const noSearchMatchLabel = props.noSearchMatchLabel || I18n.t('No matches to your search')
  const placeholder = props.placeholder || I18n.t('Begin typing to search')

  const [inputValue, setInputValue] = useState('')
  const [matcher, setMatcher] = useState(new RegExp(''))
  const [messages, setMessages] = useState<
    Array<{
      type: 'error' | 'hint' | 'success' | 'screenreader-only'
      text: React.ReactNode
    }>
    // @ts-expect-error
  >([{}])
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [selectedOptionId, setSelectedOptionId] = useState(null)
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  const [announcement, setAnnouncement] = useState('')

  const options = flattenOptions(children).map(n => ({
    id: n.props.id,
    value: n.props.value,
    name: n.props.label,
  }))
  const matchingOptions = options.filter(i => i.name?.match(matcher))
  const noResults = Children.count(children) === 0

  useEffect(() => {
    setMatcher(new RegExp(''))
    setSelectedOptionId(null)
    setIsShowingOptions(false)
    handleUpdateSearchStatusMessage(true)
    if (!value || inputValue) return
    const initialValue = options.find(i => i.value === value)
    if (initialValue) setInputValue(initialValue.name)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value, Children.count(children)])

  const matcherFor = (v: any) => new RegExp('^(\\s*)' + reEscape(v), 'i')

  const handleInputChange = (e: any) => {
    const newMatcher = matcherFor(e.target.value)
    const doesAnythingMatch = options.some(i => i.name.match(newMatcher))
    setInputValue(e.target.value)
    setMatcher(newMatcher)
    setSelectedOptionId(null)
    handleUpdateSearchStatusMessage(doesAnythingMatch)
    setIsShowingOptions(doesAnythingMatch)
  }

  // messages are not being accidentally set
  const handleUpdateSearchStatusMessage = (matches: any) => {
    if (!matches) {
      setMessages([{type: 'error', text: noSearchMatchLabel}])
      return
    }
    if (noResults) {
      setMessages([{type: 'hint', text: noResultsLabel}])
      return
    }
    // @ts-expect-error
    setMessages([{}])
  }

  const handleRequestHideOptions = (event: any) => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    if (event.type !== 'blur') setAnnouncement(I18n.t('List collapsed. ') + inputValue)
  }

  const handleRequestShowOptions = () => {
    if (messages.hasOwnProperty('type')) return
    setIsShowingOptions(true)
    setAnnouncement(I18n.t('List expanded.'))
  }

  const handleRequestHighlightOption = (event: any, {id}: any) => {
    const text = options.find(o => o.id === id)?.name
    if (event.type === 'keydown') setInputValue(text)
    setHighlightedOptionId(id)
    setAnnouncement(text)
  }

  const handleRequestSelectOption = (event: any, {id}: any) => {
    const selectedOption = options.find(o => o.id === id)
    setInputValue(selectedOption?.name)
    setMatcher(new RegExp(''))
    setSelectedOptionId(id)
    setIsShowingOptions(false)
    setAnnouncement(I18n.t('%{option} selected. List collapsed.', {option: selectedOption?.name}))
    onChange(event, {id, option: selectedOption})
  }

  const handleBlur = (e: any) => {
    // set possible selection if narrowed to a single match or disregard as no op
    const possibleSelection = matchingOptions.length === 1 ? matchingOptions[0] : false
    if (possibleSelection) {
      handleRequestSelectOption(e, possibleSelection)
      handleUpdateSearchStatusMessage(true)
    }
  }

  function renderOptions(nodes: any) {
    function renderOption(optionNode: any) {
      const {id: optionId, children: optionChildren, ...rest} = optionNode.props
      const opt = options.find(o => o.id === optionId)
      if (!opt || !opt.name.match(matcher)) return null
      return (
        <Select.Option
          id={optionId}
          key={optionNode.key || optionId || uid('backupKey', 4)}
          isHighlighted={optionId === highlightedOptionId}
          isSelected={optionId === selectedOptionId}
          {...rest}
        >
          {rest.label}
        </Select.Option>
      )
    }

    const result: (any[] | JSX.Element | null)[] = []

    Children.forEach(nodes, child => {
      if (Array.isArray(child)) {
        result.push(renderOptions(child))
      } else if (child?.type?.displayName === 'Option') {
        result.push(renderOption(child))
      }
    })

    return result
  }

  function renderChildren() {
    if (isLoading) {
      return (
        <Select.Option isDisabled={true} id={NO_OPTIONS_OPTION_ID}>
          <Spinner renderTitle={I18n.t('Loading options...')} size="small" />
        </Select.Option>
      )
    }

    if (messages.hasOwnProperty('type') && matchingOptions.length === 0) {
      return (
        <Select.Option isDisabled={true} id={NO_OPTIONS_OPTION_ID}>
          xxx
        </Select.Option>
      )
    }

    return renderOptions(children).filter(Boolean)
  }

  return (
    <>
      <Select
        id={selectId}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        assistiveText={I18n.t('Type to search, use arrow keys to navigate options.') + ' '}
        placeholder={placeholder}
        renderLabel={() => label}
        onBlur={handleBlur}
        messages={messages}
        onInputChange={handleInputChange}
        onRequestShowOptions={handleRequestShowOptions}
        onRequestHideOptions={handleRequestHideOptions}
        onRequestHighlightOption={handleRequestHighlightOption}
        onRequestSelectOption={handleRequestSelectOption}
        {...analyticProps('Role')}
      >
        {renderChildren()}
      </Select>

      <Alert
        screenReaderOnly={true}
        isLiveRegionAtomic={true}
        liveRegion={getLiveRegion}
        liveRegionPoliteness="assertive"
      >
        {announcement}
      </Alert>
    </>
  )
}

RoleSearchSelect.Option = SearchableSelectOption
