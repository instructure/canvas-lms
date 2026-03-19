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
import {useScope as createI18nScope} from '@canvas/i18n'

import {DateTime} from '@instructure/ui-i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconCalendarMonthLine} from '@instructure/ui-icons'
import {Editable} from '@instructure/ui-editable'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('assignments_2')

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

  // @ts-expect-error
  constructor(props) {
    super(props)

    this.state = {
      initialValue: props.value,
      isValid: true,
    }
    // @ts-expect-error
    this._timers = [] // track the in-flight setTimeout timers
    // @ts-expect-error
    this._elementRef = null
  }

  componentWillUnmount() {
    // @ts-expect-error
    this._timers.forEach(t => window.clearTimeout(t))
  }

  // if a new value comes in while we're in view mode,
  // reset our initial value
  // @ts-expect-error
  static getDerivedStateFromProps(props, _state) {
    if (props.mode === 'view') {
      return {
        initialValue: props.value,
      }
    }
    return null
  }

  // @ts-expect-error
  elementRef = el => {
    // @ts-expect-error
    this._elementRef = el
  }

  isValid() {
    // @ts-expect-error
    return this.state.isValid
  }

  // onChange handler from DateTimeInput
  // @ts-expect-error
  handleDateTimeChange = (_event, newValue) => {
    this.setState({isValid: true}, () => {
      // @ts-expect-error
      this.props.onChange(newValue)
    })
  }

  // onChange handler from Editable
  // @ts-expect-error
  handleChange = newValue => {
    this.setState({isValid: true}, () => {
      // @ts-expect-error
      this.props.onChange(newValue)
    })
  }

  // @ts-expect-error
  handleChangeMode = mode => {
    // @ts-expect-error
    if (!this.props.readOnly) {
      if (mode === 'view') {
        if (!this.isValid()) {
          // can't leave edit mode with a bad value
          return
        }
      }
      // @ts-expect-error
      this.props.onChangeMode(mode)
    }
  }

  // Because DateTimeInput has an asynchronous onBlur handler, we need to delay our call to
  // this EditableDateTime's onFocus handler or focus gets yanked from this to the edit button of
  // the one we just left if the user clicks from one to the next
  // @ts-expect-error
  delayedHandler = handler => {
    // @ts-expect-error
    return event => {
      event.persist()
      const t = window.setTimeout(() => {
        // @ts-expect-error
        this._timers.splice(
          // @ts-expect-error
          this._timers.findIndex(tid => tid === t),
          1,
        )
        handler(event)
      }, 100)
      // @ts-expect-error
      this._timers.push(t)
    }
  }

  // similar issue when clicking on the view
  // @ts-expect-error
  viewClickHandler(editableClickHandler) {
    if (editableClickHandler) {
      return this.delayedHandler(editableClickHandler)
    }
    return null
  }

  // @ts-expect-error
  handleKey = event => {
    if (event.key === 'Enter' && event.type === 'keydown') {
      // @ts-expect-error
      if (!this.props.readOnly) {
        // let EditableDateTime handle the value change,
        // then flip me to view mode
        const t = window.setTimeout(() => {
          // @ts-expect-error
          this._timers.splice(
            // @ts-expect-error
            this._timers.findIndex(tid => tid === t),
            1,
          )
          // @ts-expect-error
          this.props.onChangeMode('view')
        }, 100)
        // @ts-expect-error
        this._timers.push(t)
      }
    } else if (event.key === 'Escape' && event.type === 'keyup') {
      // Editable's keypup handler is what flips us to view mode
      // so we'll reset to initial value on that event, not keydown
      // @ts-expect-error
      this.props.onChange(this.state.initialValue)
    }
  }

  // @ts-expect-error
  renderViewer = ({readOnly, mode}) => {
    if (readOnly || mode === 'view') {
      // @ts-expect-error
      if (this.props.value) {
        // @ts-expect-error
        const dt = this.props.value
          ? DateTime.toLocaleString(
              // @ts-expect-error
              this.props.value,
              // @ts-expect-error
              this.props.locale,
              // @ts-expect-error
              this.props.timeZone,
              // @ts-expect-error
              this.props.displayFormat,
            )
          : ''
        return <Text>{dt}</Text>
      }
      // @ts-expect-error
      return <Text color="secondary">{this.props.placeholder}</Text>
    }
    return null
  }

  /* eslint-disable jsx-a11y/no-static-element-interactions */
  // @ts-expect-error
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
                // @ts-expect-error
                layout="stacked"
                // @ts-expect-error
                description={<ScreenReaderContent>{this.props.label}</ScreenReaderContent>}
                dateLabel={I18n.t('Date')}
                datePreviousLabel={I18n.t('previous')}
                dateNextLabel={I18n.t('next')}
                timeLabel={I18n.t('Time')}
                // @ts-expect-error
                invalidDateTimeMessage={this.props.invalidMessage}
                // @ts-expect-error
                messages={this.props.messages}
                // @ts-expect-error
                value={this.props.value}
                onChange={this.handleDateTimeChange}
                onBlur={onBlur}
                dateInputRef={editorRef}
                // @ts-expect-error
                required={this.props.required}
                // @ts-expect-error
                locale={this.props.locale}
                // @ts-expect-error
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
  // @ts-expect-error
  renderEditButton = ({onClick, onFocus, onBlur, buttonRef}) => {
    // @ts-expect-error
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
          // @ts-expect-error
          readOnly={this.props.readOnly}
          // @ts-expect-error
          screenReaderLabel={I18n.t('Edit %{when}', {when: this.props.label})}
        />
      )
    }
    return null
  }

  // @ts-expect-error
  renderAll = ({getContainerProps, getViewerProps, getEditorProps, getEditButtonProps}) => {
    // @ts-expect-error
    const borderWidth = this.props.mode === 'view' ? 'small' : 'none'
    // @ts-expect-error
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
        // @ts-expect-error
        mode={this.props.mode}
        onChangeMode={this.handleChangeMode}
        render={this.renderAll}
        // @ts-expect-error
        value={this.props.value}
        onChange={this.handleChange}
        // @ts-expect-error
        readOnly={this.props.readOnly}
      />
    )
  }
}
