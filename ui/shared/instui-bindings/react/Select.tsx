// @ts-nocheck
/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

/*
---
  CanvasSelect is a wrapper on the new (as of instui 5 or 6 or so) controlled-only Select
  While CanvasSelect is also controlled-only, it has a simpler api and is almost a drop-in
  replacement for the old instui Select used throughout canvas at this time. One big difference
  is the need to pass in an options property rather than rendering <Options> children

  It does not currently support old-Select's allowCustom property
  (see https://instructure.design/#DeprecatedSelect)

  It only handles single-select. Multi-select will likely have to be in a separate component

  <CanvasSelect
    id="your-id"
    label="select's label"
    value={value}             // should match the ID of the selected option
    onChange={handleChange}   // function(event, selectedOption)
    {...otherPropsPassedToTheUnderlyingSelect}  // if you need to (width="100%" is a popular one)
  >
    <CanvasSelect.Option key="1" id="1" value="1">one</CanvasSelect.Option>
    <CanvasSelect.Option key="2" id="2" value="2">two</CanvasSelect.Option>
    <CanvasSelect.Option key="3" id="3" value="3">three</CanvasSelect.Option>
  </CanvasSelect>
---
*/

import React, {ReactElement, ChangeEvent} from 'react'
import {compact, castArray, isEqual} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Select} from '@instructure/ui-select'
import {Alert} from '@instructure/ui-alerts'
import {matchComponentTypes} from '@instructure/ui-react-utils'

const I18n = useI18nScope('app_shared_components')
const {Option: SelectOption, Group: SelectGroup} = Select as any

const noOptionsOptionId = '_noOptionsOption'

type Props = {
  children: ReactElement | ReactElement[]
  disabled?: boolean
  id: string
  label?: ReactElement | string
  noOptionsLabel?: string
  onChange: (event: ChangeEvent, value: string) => void
  value: string
}

type State = {
  inputValue: string
  isShowingOptions: boolean
  highlightedOptionId: string | null
  selectedOptionId: string
  announcement: string | null
}

type OptionProps = {
  id: string
  value: string
}

type GroupProps = {
  label: string
}

// CanvasSelectOption and CanvasSelectGroup are components our client can create thru CanvasSelect
// to pass us our options. They are never rendered themselves, but get transformed into INSTUI's
// Select.Option and Select.Group on rendering CanvasSelect. See renderChildren below.
function CanvasSelectOption(_props: OptionProps): ReactElement {
  return <div />
}

function CanvasSelectGroup(_props: GroupProps): ReactElement {
  return <div />
}

class CanvasSelect extends React.Component<Props, State> {
  static Option = CanvasSelectOption

  static Group = CanvasSelectGroup

  constructor(props) {
    super(props)

    const option: ReactElement | null = this.getOptionByFieldValue('value', props.value)

    this.state = {
      inputValue: option ? option.props.children : '',
      isShowingOptions: false,
      highlightedOptionId: null,
      selectedOptionId: option ? option.props.id : null,
      announcement: null,
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.value !== prevProps.value || !isEqual(this.props.children, prevProps.children)) {
      const option = this.getOptionByFieldValue('value', this.props.value)
      this.setState({
        inputValue: option ? option.props.children : '',
        selectedOptionId: option ? option.props.id : '',
      })
    }
  }

  render(): ReactElement {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const {id, label, value, onChange, children, noOptionsLabel = '---', ...otherProps} = this.props

    return (
      <>
        <Select
          id={id}
          renderLabel={() => label}
          assistiveText={I18n.t('Use arrow keys to navigate options.')}
          inputValue={this.state.inputValue}
          isShowingOptions={this.state.isShowingOptions}
          onBlur={this.handleBlur}
          onRequestShowOptions={this.handleShowOptions}
          onRequestHideOptions={this.handleHideOptions}
          onRequestHighlightOption={this.handleHighlightOption}
          onRequestSelectOption={this.handleSelectOption}
          {...otherProps}
        >
          {this.renderChildren(children)}
        </Select>
        <Alert
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          liveRegionPoliteness="assertive"
          screenReaderOnly={true}
        >
          {this.state.announcement}
        </Alert>
      </>
    )
  }

  renderChildren(children: ReactElement | ReactElement[]): any {
    if (!Array.isArray(children)) {
      // children is 1 child
      if (matchComponentTypes(children, [CanvasSelectOption])) {
        return this.renderOption(children)
      } else if (matchComponentTypes(children, [CanvasSelectGroup])) {
        return this.renderGroup(children)
      } else {
        return this.renderNoOptionsOption()
      }
    }

    const opts = children
      .map((child: ReactElement | ReactElement[]) => {
        if (Array.isArray(child)) {
          return this.renderChildren(child)
        } else if (matchComponentTypes(child, [CanvasSelectOption])) {
          return this.renderOption(child)
        } else if (matchComponentTypes(child, [CanvasSelectGroup])) {
          return this.renderGroup(child)
        }
        return null
      })
      .filter(child => !!child) // instui Select blows up on undefined options

    if (opts.length === 0) {
      return this.renderNoOptionsOption()
    }
    return opts
  }

  backupKey = 0

  renderOption(option: ReactElement): ReactElement {
    const {id, children, ...optionProps} = option.props
    return (
      <SelectOption
        id={id}
        key={option.key || id || ++this.backupKey}
        isHighlighted={id === this.state.highlightedOptionId}
        isSelected={id === this.state.selectedOptionId}
        {...optionProps}
      >
        {children}
      </SelectOption>
    )
  }

  renderGroup(group: ReactElement): ReactElement {
    const {id, label, ...otherProps} = group.props
    const children = compact(castArray(group.props.children))
    return (
      <SelectGroup
        data-testid={`Group:${label}`}
        renderLabel={() => label}
        key={group.key || id || ++this.backupKey}
        {...otherProps}
      >
        {children.map(c => this.renderOption(c))}
      </SelectGroup>
    )
  }

  renderNoOptionsOption(): ReactElement {
    return (
      <SelectOption id={noOptionsOptionId} isHighlighted={false} isSelected={false}>
        {this.props.noOptionsLabel}
      </SelectOption>
    )
  }

  handleBlur = (_event: ChangeEvent): void => {
    this.setState({highlightedOptionId: null})
  }

  handleShowOptions = (): void => {
    this.setState({
      isShowingOptions: true,
    })
  }

  handleHideOptions = (_event: ChangeEvent): void => {
    this.setState(state => {
      const text = this.getOptionLabelById(state.selectedOptionId)
      return {
        isShowingOptions: false,
        highlightedOptionId: null,
        inputValue: text,
        announcement: I18n.t('List collapsed.'),
      }
    })
  }

  /* eslint-disable react/no-access-state-in-setstate */
  // Because handleShowOptions sets state.isShowingOptions:true
  // it's already in the value of state passed to the setState(updater)
  // by the time handleHighlightOption is called we miss the transition,
  // this.state still has the previous value as of the last render
  // which is what we need. This is why we use this version of setState.
  handleHighlightOption = (event: ChangeEvent, {id}): void => {
    if (id === noOptionsOptionId) return

    const text = this.getOptionLabelById(id)
    const nowOpen = this.state.isShowingOptions ? '' : I18n.t('List expanded.')
    const inputValue = event.type === 'keydown' ? text : this.state.inputValue
    this.setState({
      highlightedOptionId: id,
      inputValue,
      announcement: `${text} ${nowOpen}`,
    })
  }
  /* eslint-enable react/no-access-state-in-setstate */

  handleSelectOption = (event: ChangeEvent, {id}): void => {
    if (id === noOptionsOptionId) {
      this.setState({
        isShowingOptions: false,
        announcement: I18n.t('List collapsed'),
      })
    } else {
      const text = this.getOptionLabelById(id)
      const prevSelection = this.state.selectedOptionId
      this.setState({
        selectedOptionId: id,
        inputValue: text,
        isShowingOptions: false,
        announcement: I18n.t('%{option} selected. List collapsed.', {option: text}),
      })
      const option = this.getOptionByFieldValue('id', id)
      if (prevSelection !== id) {
        this.props.onChange(event, option?.props.value)
      }
    }
  }

  getOptionLabelById(oid: string): string {
    const option = this.getOptionByFieldValue('id', oid)
    return option ? option.props.children : ''
  }

  getOptionByFieldValue(
    field: string,
    value: string,
    options = castArray<ReactElement>(this.props.children)
  ): ReactElement | null {
    if (!this.props.children) return null

    let foundOpt: ReactElement | null = null
    for (let i = 0; i < options.length; ++i) {
      const o: ReactElement = options[i]
      if (Array.isArray(o)) {
        foundOpt = this.getOptionByFieldValue(field, value, o)
      } else if (matchComponentTypes(o, [CanvasSelectOption])) {
        if (o.props[field] === value) {
          foundOpt = o
        }
      } else if (matchComponentTypes(o, [CanvasSelectGroup])) {
        const groupOptions = castArray(o.props.children)
        for (let j = 0; j < groupOptions.length; ++j) {
          const o2 = groupOptions[j]
          if (o2.props[field] === value) {
            foundOpt = o2
            break
          }
        }
      }
      if (foundOpt) {
        break
      }
    }
    return foundOpt
  }
}

export default CanvasSelect
