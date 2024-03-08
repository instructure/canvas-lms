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

import React, {useState, useEffect, useRef, useMemo} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import keycode from 'keycode'
import {Select} from '@instructure/ui-select'
import type {ViewProps} from '@instructure/ui-view'
import {Tag} from '@instructure/ui-tag'
import {matchComponentTypes} from '@instructure/ui-react-utils'
import {compact, uniqueId} from 'lodash'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = useI18nScope('app_shared_components')

type OptionProps = {
  id: string
  value: string
  label: React.ReactNode
  tagText?: string
}

export type Size = 'small' | 'medium' | 'large'

const CanvasMultiSelectOption: React.FC = _props => <div />

function liveRegion(): HTMLElement {
  const div = document.getElementById('flash_screenreader_holder')
  if (!(div instanceof HTMLElement)) {
    throw new Error('live region not found')
  }
  return div
}

const NO_OPTIONS_OPTION_ID = '__no_option-'

type Props = {
  assistiveText?: string
  children: React.ReactNode
  customMatcher: (option: any, term: string) => boolean
  customOnInputChange: (value: string) => void
  customOnRequestHideOptions: () => void
  customOnRequestSelectOption: (ids: string[]) => void
  customOnRequestShowOptions: () => void
  customRenderBeforeInput: (tags: any) => React.ReactNode
  customOnBlur?: () => void
  disabled: boolean
  id?: string
  isLoading: boolean
  isShowingOptions?: boolean
  label: React.ReactNode
  inputRef?: (inputElement: HTMLInputElement | null) => void
  listRef?: (ref: HTMLUListElement | null) => void
  noOptionsLabel: string
  onChange: (ids: string[]) => void
  placeholder?: string
  renderAfterInput?: React.ReactNode
  selectedOptionIds: string[]
  size?: Size
  visibleOptionsCount?: number
  messages?: FormMessage[]
  onUpdateHighlightedOption?: (id: string) => void
  setInputRef?: (ref: HTMLInputElement | null) => void
}

function CanvasMultiSelect(props: Props) {
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
    customOnInputChange,
    customOnRequestShowOptions,
    customOnRequestHideOptions,
    customOnRequestSelectOption,
    customOnBlur,
    isLoading,
    onUpdateHighlightedOption,
    setInputRef,
    ...otherProps
  } = props

  const [inputValue, setInputValue] = useState<string>('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [announcement, setAnnouncement] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement | null>(null)
  const noOptionId = useRef(uniqueId(NO_OPTIONS_OPTION_ID))

  if (inputRef && setInputRef) {
    setInputRef(inputRef.current)
  }

  const childProps: OptionProps[] = useMemo<
    {
      id: string
      value: string
      label: React.ReactNode
      tagText?: string
    }[]
  >(
    () =>
      React.Children.map(children, n => {
        if (!React.isValidElement(n)) return null
        return {
          id: n.props.id,
          value: n.props.value,
          label: n.props.children,
          tagText: n.props.tagText,
        }
      }) || [],
    [children]
  )

  const [filteredOptionIds, setFilteredOptionIds] = useState<string[] | null>(null)

  function getChildById(id?: string) {
    return childProps.find(c => c.id === id)
  }

  function renderChildren(): React.ReactNode | React.ReactNode[] {
    const groups: string[] = [
      ...new Set(
        React.Children.map(children, child => {
          if (!React.isValidElement(child)) return undefined
          return child.props.group
        })
      ),
    ].filter((group: string) => group)

    function renderOption(child: {
      key: React.Key
      props: {id: string; children: React.ReactNode; key?: string; group: string; tagText?: string}
    }) {
      // eslint-disable-next-line @typescript-eslint/no-shadow
      const {id, children, ...optionProps} = child.props
      delete optionProps.tagText
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
          {isLoading ? <Spinner renderTitle="Loading" size="x-small" /> : noOptionsLabel}
        </Select.Option>
      )
    }

    const filteredChildren = compact(
      (Array.isArray(children) ? children : []).map(child => {
        if (
          matchComponentTypes(child, [CanvasMultiSelectOption]) &&
          (!filteredOptionIds || filteredOptionIds.includes(child.props.id)) &&
          !selectedOptionIds.includes(child.props.id)
        ) {
          return renderOption({
            ...child,
            key: child.key || uniqueId('multi-select-option-'),
          })
        }
        return null
      })
    )

    function renderGroups() {
      const grouplessOptions = filteredChildren.filter(o => o.props.group === undefined)
      const groupsToRender = groups.filter(group =>
        filteredChildren.some(child => child.props.group === group)
      )
      const optionsToRender = grouplessOptions.map(isolatedOption =>
        renderOption({
          ...isolatedOption,
          key: isolatedOption.key ?? uniqueId('multi-select-option-'),
        })
      )
      return [
        ...optionsToRender,
        ...groupsToRender.map(group => (
          <Select.Group key={group} renderLabel={group}>
            {filteredChildren
              // eslint-disable-next-line @typescript-eslint/no-shadow, react/prop-types
              .filter(({props}) => props.group === group)
              .map(option =>
                renderOption({
                  ...option,
                  key: option.key || uniqueId('multi-select-group-option-'),
                })
              )}
          </Select.Group>
        )),
      ]
    }

    if (filteredChildren.length === 0) return renderNoOptionsOption()

    return groups.length === 0 ? filteredChildren : renderGroups()
  }

  function dismissTag(e: React.MouseEvent<ViewProps, MouseEvent>, id: string, label: string) {
    e.stopPropagation()
    e.preventDefault()
    setAnnouncement(I18n.t('%{label} removed.', {label}))
    onChange(selectedOptionIds.filter(x => x !== id))
    inputRef?.current?.focus()
  }

  function renderTags() {
    if (!Array.isArray(children)) return null
    const options = children

    return compact(
      selectedOptionIds.map(id => {
        const opt = options.find(c => c.props.id === id)
        if (!opt) return null
        const tagText = opt.props.tagText || opt.props.children || opt.props.label
        return (
          <Tag
            dismissible={true}
            key={opt.key}
            text={tagText}
            title={I18n.t('Remove %{label}', {label: tagText})}
            margin="0 xxx-small"
            onClick={(e: React.MouseEvent<ViewProps, MouseEvent>) => dismissTag(e, id, tagText)}
          />
        )
      })
    )
  }

  function contentBeforeInput() {
    const tags = selectedOptionIds.length > 0 ? renderTags() : null
    return customRenderBeforeInput ? customRenderBeforeInput(tags) : tags
  }

  const memoizedChildprops = useMemo(() => {
    return childProps.map(({label, ...props}) => props)
  }, [childProps])

  useEffect(() => {
    if (inputValue !== '') {
      filterOptions(inputValue)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(memoizedChildprops)])

  function onInputChange(e: React.ChangeEvent<HTMLInputElement>) {
    const {value} = e.target
    filterOptions(value)
    setInputValue(value)
    customOnInputChange(value)
  }

  function filterOptions(value: string) {
    const defaultMatcher = (
      option: {
        label: string
      },
      term: string
    ) => option.label.match(new RegExp(`^${term}`, 'i'))
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
      message = getChildById(filtered[0].id)?.label + '. ' + message
    }
    setFilteredOptionIds(filtered.map(f => f.id))
    if (filtered.length > 0) setHighlightedOptionId(filtered[0].id)
    setIsShowingOptions(true)
    setAnnouncement(message)
  }

  const primaryLabel = (option: OptionProps) => option.tagText || (option.label as string)

  function onRequestShowOptions() {
    setIsShowingOptions(true)
    customOnRequestShowOptions()
  }

  function onRequestHideOptions() {
    setIsShowingOptions(false)
    customOnRequestHideOptions()
    if (!highlightedOptionId) return
    setInputValue('')
    if (filteredOptionIds?.length === 1) {
      const option = getChildById(filteredOptionIds[0])
      setAnnouncement(
        I18n.t('%{label} selected. List collapsed.', {label: option ? primaryLabel(option) : ''})
      )
      onChange([...selectedOptionIds, filteredOptionIds[0]])
    }
    setFilteredOptionIds(null)
  }

  function onRequestHighlightOption(e: any, {id}: any) {
    e.persist()
    const option = getChildById(id)
    if (typeof option === 'undefined') return
    if (e.type === 'keydown') setInputValue(primaryLabel(option))
    setHighlightedOptionId(id)
    setAnnouncement(primaryLabel(option))
    onUpdateHighlightedOption?.(id)
  }

  function onRequestSelectOption(e: React.SyntheticEvent, {id}: {id?: string}): void {
    const option = getChildById(id)
    setInputValue('')
    setFilteredOptionIds(null)
    setIsShowingOptions(false)
    if (!id || typeof option === 'undefined') return
    setAnnouncement(I18n.t('%{label} selected. List collapsed.', {label: primaryLabel(option)}))
    onChange([...selectedOptionIds, id])
    customOnRequestSelectOption([...selectedOptionIds, id])
  }

  // if backspace is pressed and there's no input to backspace over, remove the
  // last selected option if there is one
  function onKeyDown(e: any) {
    if (
      e.keyCode === keycode.codes.backspace &&
      inputValue.length === 0 &&
      selectedOptionIds.length > 0
    ) {
      const option = getChildById(selectedOptionIds.slice(-1)[0])
      setAnnouncement(I18n.t('%{label} removed.', {label: option ? primaryLabel(option) : ''}))
      onChange(selectedOptionIds.slice(0, -1))
    }
  }

  function onBlur() {
    setHighlightedOptionId(null)
    customOnBlur?.()
  }

  return (
    <>
      <Select
        id={selectId}
        disabled={disabled}
        renderLabel={renderLabel}
        inputValue={inputValue}
        inputRef={ref => {
          inputRef.current = ref
        }}
        onInputChange={onInputChange}
        onRequestShowOptions={onRequestShowOptions}
        onRequestHideOptions={onRequestHideOptions}
        isShowingOptions={isShowingOptions}
        onRequestHighlightOption={onRequestHighlightOption}
        onRequestSelectOption={onRequestSelectOption}
        onKeyDown={onKeyDown}
        onBlur={onBlur}
        assistiveText={I18n.t(
          'Type or use arrow keys to navigate. Multiple selections are allowed.'
        )}
        renderBeforeInput={contentBeforeInput()}
        {...otherProps}
      >
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

CanvasMultiSelect.defaultProps = {
  customMatcher: null,
  customRenderBeforeInput: null,
  noOptionsLabel: '---',
  selectedOptionIds: [],
  disabled: false,
  isLoading: false,
  customOnInputChange: () => {},
  customOnRequestShowOptions: () => {},
  customOnRequestHideOptions: () => {},
  customOnRequestSelectOption: (_ids: []) => {},
}

CanvasMultiSelect.Option = CanvasMultiSelectOption

export default CanvasMultiSelect
