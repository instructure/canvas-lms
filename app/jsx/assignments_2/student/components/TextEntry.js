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

import Billboard from '@instructure/ui-billboard/lib/components/Billboard'
import Button from '@instructure/ui-buttons/lib/components/Button'
import {func} from 'prop-types'
import I18n from 'i18n!assignments_2_text_entry'
import IconText from '@instructure/ui-icons/lib/Line/IconText'
import React from 'react'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import {Submission} from '../graphqlData/Submission'
import View from '@instructure/ui-layout/lib/components/View'

RichContentEditor.preloadRemoteModule()

export default class TextEntry extends React.Component {
  static propTypes = {
    createSubmissionDraft: func,
    submission: Submission.shape,
    updateUploadState: func
  }

  state = {
    editorLoaded: false
  }

  getDraftBody = () => {
    if (this.props.submission.submissionDraft) {
      return this.props.submission.submissionDraft.body
    } else {
      return null
    }
  }

  componentDidMount() {
    if (this.getDraftBody() !== null && !this.state.editorLoaded) {
      this.loadRCE()
    }
  }

  componentDidUpdate() {
    if (this.getDraftBody() !== null && !this.state.editorLoaded) {
      this.loadRCE()
    } else if (this.getDraftBody() === null && this.state.editorLoaded) {
      this.unloadRCE()
    }
  }

  componentWillUnmount() {
    if (this.state.editorLoaded) {
      this.unloadRCE()
    }
  }

  // Note: I believe there's a bug in tinymce, that
  // if you set focus:true to give the editor focus on init,
  // then the internal bookkeeping doesn't know it has focus
  // and it does not handle the focusout event correctly.
  // Start w/o focus, then give it focus after initialization
  // in this.handleRCEInit
  loadRCE() {
    this.setState({editorLoaded: true}, () => {
      RichContentEditor.loadNewEditor(this._textareaRef, {
        focus: false,
        manageParent: false,
        tinyOptions: {
          init_instance_callback: this.handleRCEInit,
          height: 300
        },
        onFocus: this.handleEditorFocus,
        onBlur: () => {}
      })
    })
  }

  unloadRCE() {
    this.setState({editorLoaded: false}, () => {
      const documentContent = document.getElementById('content')
      if (documentContent) {
        const editorIframe = documentContent.querySelector('[id^="random_editor"]')
        if (editorIframe) {
          editorIframe.removeEventListener('focus', this.handleEditorIframeFocus)
        }
      }
      if (this._textareaRef) {
        RichContentEditor.destroyRCE(this._textareaRef)
      }
      this._textareaRef = null
    })
  }

  handleRCEInit = tinyeditor => {
    this._tinyeditor = tinyeditor

    const documentContent = document.getElementById('content')
    if (documentContent) {
      const editorIframe = documentContent.querySelector('[id^="random_editor"]')
      if (editorIframe) {
        editorIframe.addEventListener('focus', this.handleEditorIframeFocus)
        this._tinyeditor.focus()
      }
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

  setTextareaRef = el => {
    this._textareaRef = el
  }

  getRCEText = () => {
    return RichContentEditor.callOnRCE(this._textareaRef, 'get_code')
  }

  updateSubmissionDraft = async rceText => {
    try {
      await this.props.createSubmissionDraft({
        variables: {
          id: this.props.submission.id,
          attempt: this.props.submission.attempt || 1,
          body: rceText
        }
      })
    } catch (err) {
      this.props.updateUploadState('error')
    }
  }

  handleStartButton = () => {
    this.updateSubmissionDraft('')
  }

  handleSaveButton = () => {
    this.updateSubmissionDraft(this.getRCEText())
  }

  handleCancelButton = () => {
    this.updateSubmissionDraft(null)
  }

  renderButtons() {
    const buttonAlign = {
      margin: '15px 0 0 0',
      position: 'absolute',
      right: '35px'
    }

    return (
      <div style={buttonAlign}>
        <Button
          data-testid="cancel-text-entry"
          margin="0 xx-small 0 0"
          onClick={this.handleCancelButton}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button data-testid="save-text-entry" onClick={this.handleSaveButton}>
          {I18n.t('Save')}
        </Button>
      </div>
    )
  }

  renderEditor() {
    return (
      <div data-testid="text-editor">
        <span>
          <textarea defaultValue={this.getDraftBody()} ref={this.setTextareaRef} />
        </span>
        {this.renderButtons()}
      </div>
    )
  }

  renderInitialBox() {
    return (
      <View as="div" borderWidth="small" data-testid="text-entry">
        <Billboard
          heading={I18n.t('Text Entry')}
          hero={<IconText color="brand" />}
          message={
            <Button data-testid="start-text-entry" onClick={this.handleStartButton}>
              {I18n.t('Start Entry')}
            </Button>
          }
        />
      </View>
    )
  }

  render() {
    if (this.getDraftBody() === null) {
      return this.renderInitialBox()
    } else {
      return this.renderEditor()
    }
  }
}
