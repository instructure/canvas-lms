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

import {bool, func, object} from 'prop-types'
import React, {createRef} from 'react'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {RceLti11ContentItem} from '@instructure/canvas-rce/es/rce/plugins/instructure_rce_external_tools/lti11-content-items/RceLti11ContentItem'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import theme from '@instructure/canvas-theme'
import StudentViewContext from '../Context'
import FormattedErrorMessage from '@canvas/assignments/react/FormattedErrorMessage'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignments_2_text_entry')

// This is how long we wait to see that changes have stopped before actually
// saving the draft
const saveDraftDelayMS = 1000
export const ERROR_MESSAGE = I18n.t('Text is required for text submission')

export default class TextEntry extends React.Component {
  static propTypes = {
    createSubmissionDraft: func,
    focusOnInit: bool.isRequired,
    onContentsChanged: func,
    submission: Submission.shape,
    readOnly: bool,
    submitButtonRef: object,
  }

  state = {
    showErrorMessage: false
  }

  _isMounted = false

  _isInitted = false

  _saveDraftTimer = null

  _lastSavedContent = null

  _rceRef = createRef()

  _rceAriaLabel = ''

  getRceIframe = () => document.getElementById('textentry_text_ifr')

  handleMessage = e => {
    const editor = this._rceRef.current
    if (editor == null || e.data.subject !== 'A2ExternalContentReady') {
      return
    }

    e.data.content_items
      .map(contentItem => RceLti11ContentItem.fromJSON(contentItem).codePayload)
      .forEach(code => {
        editor.insertCode(code)
      })
  }

  getDraftBody = () => {
    const {submission} = this.props
    if (['graded', 'submitted'].includes(submission.state)) {
      // If this attempt has been submitted/graded, use it. (It could be null
      // if a grade was given without a proper submission; the RCE will throw
      // an error in that case, so default to an empty string.)
      return submission.body || ''
    } else if (submission.submissionDraft != null) {
      // If a draft object exists, get the submission contents from it
      return submission.submissionDraft.body || ''
    }

    // If the submission is marked as unsubmitted and there's no draft object,
    // the user has started a new attempt but not entered any text, so return
    // an empty string. The body attribute may contain the contents of a
    // previous attempt, which we don't want.
    return ''
  }

  componentDidMount() {
    this._isMounted = true

    window.addEventListener('message', this.handleMessage)
    this.props.submitButtonRef?.current?.addEventListener('click', this.handleSubmitClick)
  }

  componentDidUpdate(prevProps) {
    if (this._tinyeditor == null) {
      return
    }

    if (this.props.submission.attempt !== prevProps.submission.attempt) {
      let body = this.getDraftBody()
      if (body !== this._tinyeditor.getContent()) {
        if (prevProps.submission.attempt === 0) {
          body = this._tinyeditor.getContent()
        }

        this._tinyeditor.setContent(body)
      }
      this._lastSavedContent = body

      if (this.props.focusOnInit) {
        this._rceRef?.current?.focus()
      }
    }

    this.props.submitButtonRef?.current?.addEventListener('click', this.handleSubmitClick)
  }

  componentWillUnmount() {
    this._isMounted = false
    clearTimeout(this._saveDraftTimer)
    window.removeEventListener('message', this.handleMessage)
    this.props.submitButtonRef.current?.removeEventListener('click', this.handleSubmitClick)
  }

  handleSubmitClick = () => {
    const {submission} = this.props
    if (!submission.submissionDraft?.meetsTextEntryCriteria) {
      this._rceRef.current?.focus()
      const rceIframe = this.getRceIframe()
      if (rceIframe) {
        const iframeBody = rceIframe.contentWindow.document.querySelector('body')
        iframeBody.style.border = '1.9px solid red'
        iframeBody.style.borderRadius = '3px'
        iframeBody.setAttribute('aria-label', ERROR_MESSAGE)
      }
      this.setState({showErrorMessage: true})
    }
  }

  checkForChanges = newContent => {
    // The idea here:
    // - Every time this function is called (currently when the RCE content changes),
    //   check whether the contents of the editor have changed, assuming we're
    //   in a state where we care about changes.
    // - If we see changes, call the onContentsChanged prop, and schedule a
    //   timer to actually save the draft. Further changes to the content will
    //   cancel/re-schedule this timer, so that we only actually save the draft
    //   after the user has stopped making changes for some time.
    if (!this._isInitted) {
      return
    }

    this.clearErrors()

    const {submission} = this.props

    const isNewAttempt = submission.submissionDraft == null && submission.state === 'unsubmitted'
    // If read-only *or* this is a brand new attempt with no content,
    // we don't want to save a draft, so don't bother comparing
    if (isNewAttempt && newContent === '') {
      return
    }

    const editorContents = newContent
    if (this._lastSavedContent !== editorContents) {
      this._lastSavedContent = editorContents

      this.props.onContentsChanged()

      clearTimeout(this._saveDraftTimer)
      this._saveDraftTimer = setTimeout(() => {
        this.saveSubmissionDraft({attempt: submission.attempt, rceText: editorContents})
      }, saveDraftDelayMS)
    }
  }

  clearErrors = () => {
    const rceIframe = this.getRceIframe()
    if (rceIframe) {
      const iframeBody = rceIframe.contentWindow.document.querySelector('body')
      iframeBody.style.border = ''
      iframeBody.style.borderRadius = ''
      iframeBody.setAttribute('aria-label', this._rceAriaLabel)
    }
    this.setState({showErrorMessage: false})
  }

  // Note: I believe there's a bug in tinymce, that
  // if you set focus:true to give the editor focus on init,
  // then the internal bookkeeping doesn't know it has focus
  // and it does not handle the focusout event correctly.
  // Start w/o focus, then give it focus after initialization
  // in this.handleRCEInit
  handleRCEInit = tinyeditor => {
    this._tinyeditor = tinyeditor

    document.querySelector('.canvas-rce__skins--root.rce-wrapper').style.removeProperty('margin-bottom')
    const rceIframe = document.getElementById('textentry_text_ifr')
    if (rceIframe && !this._rceAriaLabel) {
      const iframeBody = rceIframe.contentWindow.document.querySelector('body')
      this._rceAriaLabel = iframeBody.getAttribute('aria-label')
    }

    const draftBody = this.getDraftBody()
    tinyeditor.setContent(draftBody)
    this._lastSavedContent = draftBody

    if (this.props.focusOnInit) {
      this._rceRef.current.focus()
    }
    this._isInitted = true
  }

  handleEditorFocus = _event => {
    // these two lines put the caret at the end of the text when focused
    this._tinyeditor.selection.select(this._tinyeditor.getBody(), true)
    this._tinyeditor.selection.collapse(false)
  }

  getRCEText = () => {
    return this._rceRef.current?.getCode()
  }

  saveSubmissionDraft = async ({attempt, rceText}) => {
    await this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        activeSubmissionType: 'online_text_entry',
        attempt: attempt || 1,
        body: rceText,
      },
    })
  }

  renderContent() {
    return (
      <div
        data-testid="read-only-content"
        dangerouslySetInnerHTML={{
          __html: apiUserContent.convert(this.props.submission.body),
        }}
      />
    )
  }

  renderRCE(context) {
    return (
      <div
        data-testid="text-editor"
        style={{padding: `${theme.spacing.small} ${theme.spacing.xLarge}`}}
      >
        <CanvasRce
          ref={this._rceRef}
          autosave={false}
          defaultContent={this.getDraftBody()}
          editorOptions={{
            focus: false,
          }}
          height={300}
          readOnly={context.isObserver}
          textareaId="textentry_text"
          onFocus={this.handleEditorFocus}
          onBlur={() => {}}
          onInit={this.handleRCEInit}
          onContentChange={content => {
            this.checkForChanges(content)
          }}
          resourceType="assignment.submission"
        />
        {(this.state.showErrorMessage) && (
          <View as="div" padding="small x-small" background="primary">
            <FormattedErrorMessage message={ERROR_MESSAGE} />
          </View>
        )}
      </div>
    )
  }

  render() {
    return (
      <>
        {this.props.readOnly ? (
          this.renderContent()
        ) : (
          <StudentViewContext.Consumer>
            {context => this.renderRCE(context)}
          </StudentViewContext.Consumer>
        )}
      </>
    )
  }
}
