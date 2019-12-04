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

import {AlertManagerContext} from '../../../../shared/components/AlertManager'
import {Assignment} from '../../graphqlData/Assignment'
import {func} from 'prop-types'
import I18n from 'i18n!assignments_2_url_entry'
import MoreOptions from './MoreOptions'
import React from 'react'
import {Submission} from '../../graphqlData/Submission'

import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {Flex, View} from '@instructure/ui-layout'
import {IconEyeLine, IconExternalLinkLine, IconLinkLine} from '@instructure/ui-icons'
import {Link, Text} from '@instructure/ui-elements'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {TextInput} from '@instructure/ui-text-input'

const ERROR_MESSAGE = [
  {text: I18n.t('Please enter a valid url (e.g. http://example.com)'), type: 'error'}
]

class UrlEntry extends React.Component {
  state = {
    messages: [],
    typingTimeout: 0,
    url: '',
    valid: false
  }

  componentDidUpdate(prevProps) {
    if (
      this.props.submission?.submissionDraft?.url !== prevProps.submission?.submissionDraft?.url
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
  }

  updateInputState = () => {
    const url = this.props.submission.submissionDraft.url
    const valid = this.props.submission.submissionDraft.meetsUrlCriteria
    this.setState({
      messages: valid ? [] : ERROR_MESSAGE,
      url,
      valid
    })
  }

  componentWillUnmount() {
    window.removeEventListener('beforeunload', this.beforeunload)
    window.removeEventListener('message', this.handleLTIURLs)
  }

  handleLTIURLs = async e => {
    if (e.data.messageType === 'LtiDeepLinkingResponse') {
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
    if (e.data.messageType === 'A2ExternalContentReady') {
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
      url
    })
  }

  createSubmissionDraft = async url => {
    await this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        activeSubmissionType: 'online_url',
        attempt: this.props.submission.attempt || 1,
        url
      }
    })
  }

  renderURLInput = () => {
    const inputStyle = {
      maxWidth: '700px',
      marginLeft: 'auto',
      marginRight: 'auto'
    }

    return (
      <div style={inputStyle}>
        <Flex justifyItems="center" alignItems="start">
          <Flex.Item grow>
            <TextInput
              renderLabel={<ScreenReaderContent>{I18n.t('Website url input')}</ScreenReaderContent>}
              type="url"
              placeholder={I18n.t('http://')}
              value={this.state.url}
              onBlur={this.handleBlur}
              onChange={this.handleChange}
              messages={this.state.messages}
            />
          </Flex.Item>
          <Flex.Item>
            {this.state.valid && (
              <Button
                icon={IconEyeLine}
                margin="0 0 0 x-small"
                onClick={() => window.open(this.state.url)}
                data-testid="preview-button"
              >
                <ScreenReaderContent>{I18n.t('Preview website url')}</ScreenReaderContent>
              </Button>
            )}
          </Flex.Item>
          <Flex.Item margin="0 0 0 x-small">
            <MoreOptions
              assignmentID={this.props.assignment._id}
              courseID={this.props.assignment.env.courseId}
              userID={this.props.assignment.env.currentUser.id}
            />
          </Flex.Item>
        </Flex>
      </div>
    )
  }

  renderAttempt = () => (
    <View as="div" borderWidth="small" data-testid="url-entry" margin="0 0 medium 0">
      <Billboard
        heading={I18n.t('Website Url')}
        hero={<IconLinkLine color="brand" />}
        message={this.renderURLInput()}
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
              {this.props.submission.url}
            </Link>
          </Text>
        </Flex.Item>
      </Flex>
    )
  }

  render() {
    if (['submitted', 'graded'].includes(this.props.submission.state)) {
      return this.renderSubmission()
    } else {
      return this.renderAttempt()
    }
  }
}

UrlEntry.propTypes = {
  assignment: Assignment.shape,
  createSubmissionDraft: func,
  submission: Submission.shape,
  updateEditingDraft: func
}

UrlEntry.contextType = AlertManagerContext

export default UrlEntry
