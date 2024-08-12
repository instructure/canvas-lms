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

  constructor(props) {
    super(props)

    this.state = {
      value: props.value,
      initialValue: props.value,
      htmlValue: apiUserContent.convert(props.value),
    }
  }

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
    if (this.props.mode === 'edit') {
      this.loadRCE()
    }
  }

  componentDidUpdate(prevProps) {
    if (prevProps.mode === 'view' && this.props.mode === 'edit') {
      this.loadRCE()
    }
  }

  componentWillUnmount() {
    if (this.props.mode === 'edit') {
      this.unloadRCE()
    }
  }

  testDiv = null

  renderView = () => {
    const html = this.state.htmlValue
    // if the htmlValue is nothing but whitespace,
    // show the placeholder
    if (!this.testDiv) {
      this.testDiv = document.createElement('div')
    }
    this.testDiv.innerHTML = html
    const hasContent = !!this.testDiv.textContent.trim()
    return (
      <View as="div" margin="small 0">
        {hasContent || this.props.readOnly ? (
          <div dangerouslySetInnerHTML={{__html: html}} />
        ) : (
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
    const editorIframe = document.getElementById('content').querySelector('[id^="random_editor"]')
    if (editorIframe) {
      editorIframe.removeEventListener('focus', this.handleEditorIframeFocus)
    }
    if (this._textareaRef) {
      RichContentEditor.destroyRCE(this._textareaRef)
    }
    this._textareaRef = null
  }

  handleRCEInit = tinyeditor => {
    this._tinyeditor = tinyeditor

    document
      .getElementById('content')
      .querySelector('[id^="random_editor"]')
      .addEventListener('focus', this.handleEditorIframeFocus)
    this._tinyeditor.focus()
  }

  handleEditorBlur = event => {
    if (this._textareaRef) {
      const txt = RichContentEditor.callOnRCE(this._textareaRef, 'get_code')
      this.setState({value: txt})
      this._onBlurEditor(event)
    }
  }

  handleEditorIframeFocus = _event => {
    this._tinyeditor.focus()
  }

  handleEditorFocus = _event => {
    // these two lines put the caret at the end of the text when focused
    this._tinyeditor.selection.select(this._tinyeditor.getBody(), true)
    this._tinyeditor.selection.collapse(false)
  }

  textareaRef = el => {
    this._textareaRef = el
  }

  renderEditor = ({onBlur, editorRef}) => {
    this._onBlurEditor = onBlur
    this._editorRef = editorRef
    editorRef(this)
    return <textarea defaultValue={this.state.value} ref={this.textareaRef} />
  }

  // the Editable component thinks I'm the editor
  focus = () => {
    if (this._tinyeditor) {
      this._tinyeditor.focus(true)
    }
  }

  renderEditButton = props => {
    if (!this.props.readOnly) {
      props.label = this.props.label
      return InPlaceEdit.renderDefaultEditButton(props)
    }
    return null
  }

  handleChange = event => {
    this.setState(
      {
        value: event.target.value,
        htmlValue: apiUserContent.convert(event.target.value),
      },
      () => {
        this.props.onChange(this.state.value)
      }
    )
  }

  handleModeChange = mode => {
    if (!this.props.readOnly) {
      if (this.props.mode === 'edit') {
        this.unloadRCE()
      } else if (this._editorRef) {
        this._editorRef(null)
      }
      this.props.onChangeMode(mode)
    }
  }

  getRef = el => (this._elemRef = el)

  render() {
    return (
      <InPlaceEdit
        mode={this.props.mode}
        onChangeMode={this.handleModeChange}
        renderViewer={this.renderView}
        renderEditor={this.renderEditor}
        renderEditButton={this.renderEditButton}
        value={this.state.value}
        onChange={this.props.onChange}
        editButtonPlacement="end"
        readOnly={this.props.readOnly}
        inline={false}
      />
    )
  }
}
