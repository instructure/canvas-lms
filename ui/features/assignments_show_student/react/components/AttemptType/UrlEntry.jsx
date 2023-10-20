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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {bool, func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {isSubmitted} from '../../helpers/SubmissionHelpers'
import MoreOptions from './MoreOptions/index'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import React, {createRef} from 'react'

import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconEyeLine, IconExternalLinkLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import StudentViewContext from '../Context'
import {TextInput} from '@instructure/ui-text-input'

const I18n = useI18nScope('assignments_2_url_entry')

const ERROR_MESSAGE = [
  {text: I18n.t('Please enter a valid url (e.g. https://example.com)'), type: 'error'},
]

class UrlEntry extends React.Component {
  state = {
    messages: [],
    typingTimeout: 0,
    url: '',
    valid: false,
  }

  _urlInputRef = createRef()

  componentDidUpdate(prevProps) {
    if (
      this.props.submission?.submissionDraft?.url &&
      this.props.submission.submissionDraft.url !== prevProps.submission?.submissionDraft?.url
    ) {
      this.updateInputState()
    }
  }

  componentDidMount() {
    window.addEventListener('beforeunload', this.beforeunload)
    if (this.props.submission?.submissionDraft?.url) {
      this.updateInputState()
    }
    window.addEventListener('message', this.handleLTIURLs)

    if (this.props.focusOnInit && !isSubmitted(this.props.submission)) {
      this._urlInputRef.current.focus()
    }
  }

  updateInputState = () => {
    const url = this.props.submission.submissionDraft.url
    const valid = this.props.submission.submissionDraft.meetsUrlCriteria
    this.setState({
      messages: valid ? [] : ERROR_MESSAGE,
      url,
      valid,
    })
  }

  componentWillUnmount() {
    window.removeEventListener('beforeunload', this.beforeunload)
    window.removeEventListener('message', this.handleLTIURLs)
  }

  handleLTIURLs = async e => {
    if (e.data.subject === 'LtiDeepLinkingResponse') {
      if (e.data.errormsg) {
        this.context.setOnFailure(e.data.errormsg)
        return
      }
      if (e.data.content_items.length) {
        const url = e.data.content_items[0].url
        this.createSubmissionDraft(url)
      }
    }

    // Since LTI 1.0 handles its own message alerting we don't have to
    if (e.data.subject === 'A2ExternalContentReady') {
      if (!e.data.errormsg && e.data.content_items.length) {
        const url = e.data.content_items[0].url
        this.createSubmissionDraft(url)
      }
    }
  }

  // Warn the user if they are attempting to leave the page with an unsubmitted url entry
  beforeunload = e => {
    if (this.state.url && this.state.url !== this.props.submission?.submissionDraft?.url) {
      e.preventDefault()
      e.returnValue = true
    }
  }

  handleBlur = e => {
    this.props.updateEditingDraft(false)
    if (this.state.typingTimeout) {
      clearTimeout(this.state.typingTimeout)
    }
    this.createSubmissionDraft(e.target.value)
  }

  handleChange = e => {
    this.props.updateEditingDraft(true)
    if (this.state.typingTimeout) {
      clearTimeout(this.state.typingTimeout)
    }
    const url = e.target.value

    this.setState({
      typingTimeout: setTimeout(async () => {
        await this.createSubmissionDraft(url)
        this.props.updateEditingDraft(false)
      }, 1000), // set a timeout of 1 second
      url,
    })
  }

  createSubmissionDraft = async url => {
    await this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        activeSubmissionType: 'online_url',
        attempt: this.props.submission.attempt || 1,
        url,
      },
    })
  }

  renderURLInput = () => {
    const inputStyle = {
      maxWidth: '700px',
      marginLeft: 'auto',
      marginRight: 'auto',
    }

    return (
      <StudentViewContext.Consumer>
        {context => (
          <Flex direction="column">
            <Flex.Item overflowY="visible">
              <div style={inputStyle}>
                <Flex justifyItems="center" alignItems="start">
                  <Flex.Item shouldGrow={true}>
                    <TextInput
                      renderLabel={
                        <ScreenReaderContent>{I18n.t('Website url input')}</ScreenReaderContent>
                      }
                      type="url"
                      placeholder={I18n.t('https://')}
                      value={this.state.url}
                      onBlur={this.handleBlur}
                      onChange={this.handleChange}
                      messages={this.state.messages}
                      ref={this._urlInputRef}
                      data-testid="url-input"
                      interaction={!context.allowChangesToSubmission ? 'readonly' : 'enabled'}
                    />
                  </Flex.Item>
                  <Flex.Item>
                    {this.state.valid && (
                      <Button
                        renderIcon={IconEyeLine}
                        margin="0 0 0 x-small"
                        onClick={() => window.open(this.state.url)}
                        data-testid="preview-button"
                      >
                        <ScreenReaderContent>{I18n.t('Preview website url')}</ScreenReaderContent>
                      </Button>
                    )}
                  </Flex.Item>
                </Flex>
              </div>
            </Flex.Item>
            <Flex.Item margin="small 0" overflowY="visible">
              <MoreOptions
                assignmentID={this.props.assignment._id}
                courseID={this.props.assignment.env.courseId}
                userID={this.props.assignment.env.currentUser.id}
              />
            </Flex.Item>
          </Flex>
        )}
      </StudentViewContext.Consumer>
    )
  }

  renderAttempt = () => (
    <View as="div" data-testid="url-entry" margin="0 0 medium 0">
      <Billboard
        heading={I18n.t('Enter Web URL')}
        headingAs="span"
        headingLevel="h4"
        message={this.renderURLInput()}
        themeOverride={{backgroundColor: 'transparent'}}
      />
    </View>
  )

  renderSubmission = () => {
    return (
      <Flex direction="column">
        <Flex.Item textAlign="center" margin="small 0 medium 0">
          <Text size="large">
            <Link
              icon={IconExternalLinkLine}
              iconPlacement="end"
              margin="small"
              onClick={() => window.open(this.props.submission.url)}
            >
              <span data-testid="url-submission-text">{this.props.submission.url}</span>
            </Link>
          </Text>
        </Flex.Item>
      </Flex>
    )
  }

  render() {
    if (isSubmitted(this.props.submission)) {
      return this.renderSubmission()
    } else {
      return this.renderAttempt()
    }
  }
}

UrlEntry.propTypes = {
  assignment: Assignment.shape,
  createSubmissionDraft: func,
  focusOnInit: bool.isRequired,
  submission: Submission.shape,
  updateEditingDraft: func,
}

UrlEntry.contextType = AlertManagerContext

export default UrlEntry
