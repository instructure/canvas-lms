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

import {bool, func} from 'prop-types'
import React from 'react'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import LoadingIndicator from '@canvas/loading-indicator'

// This is the interval (in ms) at which we check for changes to the text
// content
const checkForChangesIntervalMS = 250

// This is how long we wait to see that changes have stopped before actually
// saving the draft
const saveDraftDelayMS = 1000

export default class TextEntry extends React.Component {
  static propTypes = {
    createSubmissionDraft: func,
    onContentsChanged: func,
    submission: Submission.shape,
    readOnly: bool
  }

  state = {
    editorLoaded: false,
    renderingEditor: false
  }

  _isMounted = false

  _saveDraftTimer = null

  _checkForChangesTimer = null

  _lastSavedContent = null

  getDraftBody = () => {
    const {submission} = this.props
    if (['graded', 'submitted'].includes(submission.state)) {
      // If this attempt has been submitted/graded, use it
      return submission.body
    } else if (submission.submissionDraft != null) {
      // If a draft object exists, get the submission contents from it
      return submission.submissionDraft.body
    }

    // If the submission is marked as unsubmitted and there's no draft object,
    // the user has started a new attempt but not entered any text, so return
    // an empty string. The body attribute may contain the contents of a
    // previous attempt, which we don't want.
    return ''
  }

  componentDidMount() {
    this._isMounted = true

    if (this.getDraftBody() != null && !this.state.editorLoaded) {
      this.loadRCE()
    }
  }

  componentDidUpdate(prevProps) {
    if (this._tinyeditor == null) {
      return
    }

    if (this.props.readOnly !== prevProps.readOnly) {
      this._tinyeditor.mode.set(this.props.readOnly ? 'readonly' : 'design')
    }

    if (this.props.submission.attempt !== prevProps.submission.attempt) {
      const body = this.getDraftBody()
      this._tinyeditor.setContent(body)
      this._lastSavedContent = body

      if (!this.props.readOnly) {
        this.handleEditorIframeFocus()
        this.handleEditorFocus()
      }
    }
  }

  componentWillUnmount() {
    this._isMounted = false

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
    this.setState({editorLoaded: true, renderingEditor: true}, () => {
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
    this.setState({editorLoaded: false, renderingEditor: false})

    clearInterval(this._checkForChangesTimer)
    clearTimeout(this._saveDraftTimer)
  }

  checkForChanges = () => {
    // The idea here:
    // - Every time this function is called (currently several times a second),
    //   check whether the contents of the editor have changed, assuming we're
    //   in a state where we care about changes.
    // - If we see changes, call the onContentsChanged prop, and schedule a
    //   timer to actually save the draft. Further changes to the content will
    //   cancel/re-schedule this timer, so that we only actually save the draft
    //   after the user has stopped making changes for some time.
    const {submission} = this.props

    const isNewAttempt = submission.submissionDraft == null && submission.state === 'unsubmitted'
    // If read-only *or* this is a brand new attempt with no content,
    // we don't want to save a draft, so don't bother comparing
    if (this.props.readOnly || (this._tinyeditor.getContent() === '' && isNewAttempt)) {
      return
    }

    const editorContents = this._tinyeditor.getContent()
    if (this._lastSavedContent !== editorContents) {
      this._lastSavedContent = editorContents

      this.props.onContentsChanged()

      clearTimeout(this._saveDraftTimer)
      this._saveDraftTimer = setTimeout(() => {
        this.saveSubmissionDraft({attempt: submission.attempt, rceText: editorContents})
      }, saveDraftDelayMS)
    }
  }

  handleRCEInit = tinyeditor => {
    this._tinyeditor = tinyeditor
    tinyeditor.mode.set(this.props.readOnly ? 'readonly' : 'design')

    const draftBody = this.getDraftBody()
    tinyeditor.setContent(draftBody)
    this._lastSavedContent = draftBody
    this._checkForChangesTimer = setInterval(this.checkForChanges, checkForChangesIntervalMS)

    const documentContent = document.getElementById('content')
    if (documentContent) {
      const editorIframe = documentContent.querySelector('[id^="random_editor"]')
      if (editorIframe) {
        editorIframe.addEventListener('focus', this.handleEditorIframeFocus)
        this._tinyeditor.focus()
      }
    }
    this.setState({renderingEditor: false})
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

  saveSubmissionDraft = async ({attempt, rceText}) => {
    await this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        activeSubmissionType: 'online_text_entry',
        attempt: attempt || 1,
        body: rceText
      }
    })
  }

  render() {
    return (
      <div data-testid="text-editor">
        {this.state.renderingEditor && <LoadingIndicator />}
        <span>
          <textarea
            defaultValue={this.getDraftBody()}
            readOnly={this.props.readOnly}
            ref={this.setTextareaRef}
          />
        </span>
      </div>
    )
  }
}
