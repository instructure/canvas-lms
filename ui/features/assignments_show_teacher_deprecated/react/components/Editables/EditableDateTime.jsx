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

import React from 'react'
import {arrayOf, bool, func, shape, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {DateTime} from '@instructure/ui-i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconCalendarMonthLine} from '@instructure/ui-icons'
import {Editable} from '@instructure/ui-editable'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2')

/*
 *  CAUTION: The InstUI DateTimeInput component was deprecated in v7.
 *  Rather than perform the InstUI upgrade for this part of assignments
 *  2, we are just going to short out those components and skip the tests.
 */
const DateTimeInput = () => <div className="fake-editable-datetime" />
export default class EditableDateTime extends React.Component {
  static propTypes = {
    label: string.isRequired,
    locale: string.isRequired,
    timeZone: string.isRequired,
    displayFormat: string,
    value: string, // iso8601 datetime
    mode: string.isRequired,
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    invalidMessage: func.isRequired,
    messages: arrayOf(shape({type: string.isRequired, text: string.isRequired})),
    readOnly: bool,
    required: bool,
    placeholder: string,
  }

  static defaultProps = {
    displayFormat: 'lll',
    readOnly: false,
    required: false,
  }

  constructor(props) {
    super(props)

    this.state = {
      initialValue: props.value,
      isValid: true,
    }
    this._timers = [] // track the in-flight setTimeout timers
    this._elementRef = null
  }

  componentWillUnmount() {
    this._timers.forEach(t => window.clearTimeout(t))
  }

  // if a new value comes in while we're in view mode,
  // reset our initial value
  static getDerivedStateFromProps(props, _state) {
    if (props.mode === 'view') {
      return {
        initialValue: props.value,
      }
    }
    return null
  }

  elementRef = el => {
    this._elementRef = el
  }

  isValid() {
    return this.state.isValid
  }

  // onChange handler from DateTimeInput
  handleDateTimeChange = (_event, newValue) => {
    this.setState({isValid: true}, () => {
      this.props.onChange(newValue)
    })
  }

  // onChange handler from Editable
  handleChange = newValue => {
    this.setState({isValid: true}, () => {
      this.props.onChange(newValue)
    })
  }

  handleChangeMode = mode => {
    if (!this.props.readOnly) {
      if (mode === 'view') {
        if (!this.isValid()) {
          // can't leave edit mode with a bad value
          return
        }
      }
      this.props.onChangeMode(mode)
    }
  }

  // Because DateTimeInput has an asynchronous onBlur handler, we need to delay our call to
  // this EditableDateTime's onFocus handler or focus gets yanked from this to the edit button of
  // the one we just left if the user clicks from one to the next
  delayedHandler = handler => {
    return event => {
      event.persist()
      const t = window.setTimeout(() => {
        this._timers.splice(
          this._timers.findIndex(tid => tid === t),
          1
        )
        handler(event)
      }, 100)
      this._timers.push(t)
    }
  }

  // similar issue when clicking on the view
  viewClickHandler(editableClickHandler) {
    if (editableClickHandler) {
      return this.delayedHandler(editableClickHandler)
    }
    return null
  }

  handleKey = event => {
    if (event.key === 'Enter' && event.type === 'keydown') {
      if (!this.props.readOnly) {
        // let EditableDateTime handle the value change,
        // then flip me to view mode
        const t = window.setTimeout(() => {
          this._timers.splice(
            this._timers.findIndex(tid => tid === t),
            1
          )
          this.props.onChangeMode('view')
        }, 100)
        this._timers.push(t)
      }
    } else if (event.key === 'Escape' && event.type === 'keyup') {
      // Editable's keypup handler is what flips us to view mode
      // so we'll reset to initial value on that event, not keydown
      this.props.onChange(this.state.initialValue)
    }
  }

  renderViewer = ({readOnly, mode}) => {
    if (readOnly || mode === 'view') {
      if (this.props.value) {
        const dt = this.props.value
          ? DateTime.toLocaleString(
              this.props.value,
              this.props.locale,
              this.props.timeZone,
              this.props.displayFormat
            )
          : ''
        return <Text>{dt}</Text>
      }
      return <Text color="secondary">{this.props.placeholder}</Text>
    }
    return null
  }

  /* eslint-disable jsx-a11y/no-static-element-interactions */
  renderEditor = ({mode, readOnly, onBlur, editorRef}) => {
    if (!readOnly && mode === 'edit') {
      return (
        <div
          onKeyDown={this.handleKey}
          onKeyUp={this.handleKey}
          data-testid="EditableDateTime-editor"
        >
          <View display="block" width="100%">
            <View display="inline-block" padding="x-small">
              <DateTimeInput
                layout="stacked"
                description={<ScreenReaderContent>{this.props.label}</ScreenReaderContent>}
                dateLabel={I18n.t('Date')}
                datePreviousLabel={I18n.t('previous')}
                dateNextLabel={I18n.t('next')}
                timeLabel={I18n.t('Time')}
                invalidDateTimeMessage={this.props.invalidMessage}
                messages={this.props.messages}
                value={this.props.value}
                onChange={this.handleDateTimeChange}
                onBlur={onBlur}
                dateInputRef={editorRef}
                required={this.props.required}
                locale={this.props.locale}
                timezone={this.props.timeZone}
              />
            </View>
          </View>
        </div>
      )
    }
    return null
  }
  /* eslint-enable jsx-a11y/no-static-element-interactions */

  // Renders the edit button.
  // Returns a custom edit button with the calendar icon and is always visible in view mode
  renderEditButton = ({onClick, onFocus, onBlur, buttonRef}) => {
    if (!this.props.readOnly && this.props.mode === 'view') {
      return (
        <IconButton
          size="small"
          margin="0 0 0 x-small"
          withBackground={false}
          withBorder={false}
          renderIcon={IconCalendarMonthLine}
          onClick={onClick}
          onFocus={this.delayedHandler(onFocus)}
          onBlur={onBlur}
          elementRef={buttonRef}
          readOnly={this.props.readOnly}
          screenReaderLabel={I18n.t('Edit %{when}', {when: this.props.label})}
        />
      )
    }
    return null
  }

  renderAll = ({getContainerProps, getViewerProps, getEditorProps, getEditButtonProps}) => {
    const borderWidth = this.props.mode === 'view' ? 'small' : 'none'
    const padding = this.props.mode === 'view' ? 'x-small' : '0'
    const containerProps = {...getContainerProps()}
    containerProps.onMouseDown = this.viewClickHandler(containerProps.onMouseDown)
    return (
      <View
        data-testid="EditableDateTime"
        as="div"
        padding={padding}
        borderWidth={borderWidth}
        borderRadius="medium"
        elementRef={this.elementRef}
        {...containerProps}
      >
        <Flex display="inline-flex" direction="row" justifyItems="space-between" width="100%">
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            {this.renderEditor(getEditorProps())}
            {this.renderViewer(getViewerProps())}
          </Flex.Item>
          <Flex.Item margin="0 0 0 xx-small">
            {this.renderEditButton(getEditButtonProps())}
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  render() {
    return (
      <Editable
        mode={this.props.mode}
        onChangeMode={this.handleChangeMode}
        render={this.renderAll}
        value={this.props.value}
        onChange={this.handleChange}
        readOnly={this.props.readOnly}
      />
    )
  }
}
