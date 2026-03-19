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

import React from 'react'
import {bool, string, func, oneOf} from 'prop-types'
import apiUserContent from '@canvas/util/jquery/apiUserContent'

import {InPlaceEdit} from '@instructure/ui-editable'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import RichContentEditor from '@canvas/rce/RichContentEditor'

RichContentEditor.preloadRemoteModule()

export default class EditableRichText extends React.Component {
  static propTypes = {
    mode: oneOf(['view', 'edit']).isRequired,
    label: string.isRequired, // label for the input element when in edit mode
    value: string.isRequired, // the current text
    onChange: func.isRequired, // when flips from edit to view, notify consumer of the new value
    onChangeMode: func.isRequired, // when mode changes
    placeholder: string, // the string to display when the text value is empty
    readOnly: bool,
  }

  static defaultProps = {
    placeholder: '',
    readOnly: false,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    this.state = {
      value: props.value,
      initialValue: props.value,
      htmlValue: apiUserContent.convert(props.value),
    }
  }

  // @ts-expect-error
  static getDerivedStateFromProps(props, state) {
    if (state.initialValue !== props.value) {
      const newState = {...state}
      newState.value = props.value
      newState.initialValue = props.value
      newState.htmlValue = apiUserContent.convert(props.value)
      return newState
    }
    return null
  }

  componentDidMount() {
    // @ts-expect-error
    if (this.props.mode === 'edit') {
      this.loadRCE()
    }
  }

  // @ts-expect-error
  componentDidUpdate(prevProps) {
    // @ts-expect-error
    if (prevProps.mode === 'view' && this.props.mode === 'edit') {
      this.loadRCE()
    }
  }

  componentWillUnmount() {
    // @ts-expect-error
    if (this.props.mode === 'edit') {
      this.unloadRCE()
    }
  }

  testDiv = null

  renderView = () => {
    // @ts-expect-error
    const html = this.state.htmlValue
    // if the htmlValue is nothing but whitespace,
    // show the placeholder
    if (!this.testDiv) {
      // @ts-expect-error
      this.testDiv = document.createElement('div')
    }
    // @ts-expect-error
    this.testDiv.innerHTML = html
    // @ts-expect-error
    const hasContent = !!this.testDiv.textContent.trim()
    return (
      <View as="div" margin="small 0">
        {/* @ts-expect-error */}
        {hasContent || this.props.readOnly ? (
          <div dangerouslySetInnerHTML={{__html: html}} />
        ) : (
          // @ts-expect-error
          <Text color="secondary">{this.props.placeholder}</Text>
        )}
      </View>
    )
  }

  // Note: I believe there's a bug in tinymce, that
  // if you set focus:true to give the editor focus on init,
  // then the internal bookkeeping doesn't know it has focus
  // and it does not handle the focusout event correctly.
  // Start w/o focus, then give it focus after initialization
  // in this.handleRCEInit
  loadRCE() {
    // @ts-expect-error
    RichContentEditor.loadNewEditor(this._textareaRef, {
      focus: false,
      manageParent: false,
      tinyOptions: {
        init_instance_callback: this.handleRCEInit,
        height: 300,
      },
      onFocus: this.handleEditorFocus,
      onBlur: this.handleEditorBlur,
    })
  }

  unloadRCE() {
    // @ts-expect-error
    const editorIframe = document.getElementById('content').querySelector('[id^="random_editor"]')
    if (editorIframe) {
      editorIframe.removeEventListener('focus', this.handleEditorIframeFocus)
    }
    // @ts-expect-error
    if (this._textareaRef) {
      // @ts-expect-error
      RichContentEditor.destroyRCE(this._textareaRef)
    }
    // @ts-expect-error
    this._textareaRef = null
  }

  // @ts-expect-error
  handleRCEInit = tinyeditor => {
    // @ts-expect-error
    this._tinyeditor = tinyeditor

    // @ts-expect-error
    document
      .getElementById('content')
      .querySelector('[id^="random_editor"]')
      .addEventListener('focus', this.handleEditorIframeFocus)
    // @ts-expect-error
    this._tinyeditor.focus()
  }

  // @ts-expect-error
  handleEditorBlur = event => {
    // @ts-expect-error
    if (this._textareaRef) {
      // @ts-expect-error
      const txt = RichContentEditor.callOnRCE(this._textareaRef, 'get_code')
      this.setState({value: txt})
      // @ts-expect-error
      this._onBlurEditor(event)
    }
  }

  // @ts-expect-error
  handleEditorIframeFocus = _event => {
    // @ts-expect-error
    this._tinyeditor.focus()
  }

  // @ts-expect-error
  handleEditorFocus = _event => {
    // these two lines put the caret at the end of the text when focused
    // @ts-expect-error
    this._tinyeditor.selection.select(this._tinyeditor.getBody(), true)
    // @ts-expect-error
    this._tinyeditor.selection.collapse(false)
  }

  // @ts-expect-error
  textareaRef = el => {
    // @ts-expect-error
    this._textareaRef = el
  }

  // @ts-expect-error
  renderEditor = ({onBlur, editorRef}) => {
    // @ts-expect-error
    this._onBlurEditor = onBlur
    // @ts-expect-error
    this._editorRef = editorRef
    editorRef(this)
    // @ts-expect-error
    return <textarea defaultValue={this.state.value} ref={this.textareaRef} />
  }

  // the Editable component thinks I'm the editor
  focus = () => {
    // @ts-expect-error
    if (this._tinyeditor) {
      // @ts-expect-error
      this._tinyeditor.focus(true)
    }
  }

  // @ts-expect-error
  renderEditButton = props => {
    // @ts-expect-error
    if (!this.props.readOnly) {
      // @ts-expect-error
      props.label = this.props.label
      return InPlaceEdit.renderDefaultEditButton(props)
    }
    return null
  }

  // @ts-expect-error
  handleChange = event => {
    this.setState(
      {
        value: event.target.value,
        htmlValue: apiUserContent.convert(event.target.value),
      },
      () => {
        // @ts-expect-error
        this.props.onChange(this.state.value)
      },
    )
  }

  // @ts-expect-error
  handleModeChange = mode => {
    // @ts-expect-error
    if (!this.props.readOnly) {
      // @ts-expect-error
      if (this.props.mode === 'edit') {
        this.unloadRCE()
        // @ts-expect-error
      } else if (this._editorRef) {
        // @ts-expect-error
        this._editorRef(null)
      }
      // @ts-expect-error
      this.props.onChangeMode(mode)
    }
  }

  // @ts-expect-error
  getRef = el => (this._elemRef = el)

  render() {
    return (
      <InPlaceEdit
        // @ts-expect-error
        mode={this.props.mode}
        onChangeMode={this.handleModeChange}
        renderViewer={this.renderView}
        renderEditor={this.renderEditor}
        renderEditButton={this.renderEditButton}
        // @ts-expect-error
        value={this.state.value}
        // @ts-expect-error
        onChange={this.props.onChange}
        editButtonPlacement="end"
        // @ts-expect-error
        readOnly={this.props.readOnly}
        inline={false}
      />
    )
  }
}
