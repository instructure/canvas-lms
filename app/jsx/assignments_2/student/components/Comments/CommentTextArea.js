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
import Alert from '@instructure/ui-alerts/lib/components/Alert'
import Button from '@instructure/ui-buttons/lib/components/Button'
import I18n from 'i18n!assignments_2'
import IconAudio from '@instructure/ui-icons/lib/Line/IconAudio'
import IconMedia from '@instructure/ui-icons/lib/Line/IconMedia'
import IconPaperclip from '@instructure/ui-icons/lib/Line/IconPaperclip'
import React, {Component} from 'react'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import {Mutation} from 'react-apollo'
import {
  CREATE_SUBMISSION_COMMENT,
  SUBMISSION_COMMENT_QUERY,
  StudentAssignmentShape
} from '../../assignmentData'

const ALERT_TIMEOUT = 5000

export default class CommentTextArea extends Component {
  static propTypes = {
    assignment: StudentAssignmentShape
  }

  state = {
    commentText: ''
  }

  queryVariables() {
    return {
      query: SUBMISSION_COMMENT_QUERY,
      variables: {
        submissionId: this.props.assignment.submissionsConnection.nodes[0].id.toString()
      }
    }
  }

  optimisticResponse() {
    return {
      createSubmissionComment: {
        submissionComment: {
          _id: 'pending',
          comment: this.state.commentText,
          updatedAt: new Date().toISOString(),
          attachments: [],
          author: {
            avatarUrl: this.props.assignment.env.currentUser.avatar_image_url,
            shortName: this.props.assignment.env.currentUser.display_name,
            __typename: 'User'
          },
          mediaObject: null, // When we handle upload of media comments we will handle this
          __typename: 'SubmissionComment'
        },
        __typename: 'CreateSubmissionCommentPayload'
      }
    }
  }

  updateSubmissionCommentCache = (cache, submission) => {
    const {submissionComments} = cache.readQuery(this.queryVariables())
    submissionComments.commentsConnection.nodes = submissionComments.commentsConnection.nodes.concat(
      [submission.data.createSubmissionComment.submissionComment]
    )
    cache.writeQuery({
      ...this.queryVariables(),
      data: {submissionComments}
    })
  }

  onTextChange = e => {
    this.setState({commentText: e.target.value})
  }

  onSendComment = createSubmissionComment => {
    createSubmissionComment({
      variables: {
        id: this.props.assignment.submissionsConnection.nodes[0]._id,
        comment: this.state.commentText
      }
    })
    this.setState({commentText: ''})
  }

  renderAlert(data, error) {
    return (
      <React.Fragment>
        {data && (
          <Alert
            screenReaderOnly
            liveRegion={() => document.getElementById('flash_screenreader_holder')}
            timeout={ALERT_TIMEOUT}
          >
            {I18n.t('Submission comment sent')}
          </Alert>
        )}
        {error && (
          <Alert variant="error" margin="small" timeout={ALERT_TIMEOUT}>
            {I18n.t('Error sending submission comment')}
          </Alert>
        )}
      </React.Fragment>
    )
  }

  render() {
    return (
      <Mutation
        optimisticResponse={this.optimisticResponse()}
        update={this.updateSubmissionCommentCache}
        mutation={CREATE_SUBMISSION_COMMENT}
      >
        {(createSubmissionComment, {data, error}) => (
          <div>
            {this.renderAlert(data, error)}
            <div>
              <TextArea
                onChange={this.onTextChange}
                value={this.state.commentText}
                placeholder={I18n.t('Submit a Comment')}
                resize="both"
                label={<ScreenReaderContent>{I18n.t('Comment input box')}</ScreenReaderContent>}
              />
            </div>
            <div className="textarea-action-button-container">
              <Button size="small" margin="0 x-small 0 0" variant="icon" icon={IconPaperclip}>
                <ScreenReaderContent>{I18n.t('Attach a File')}</ScreenReaderContent>
              </Button>
              <Button size="small" margin="0 x-small 0 0" variant="icon" icon={IconMedia}>
                <ScreenReaderContent>{I18n.t('Record Video')}</ScreenReaderContent>
              </Button>
              <Button size="small" margin="0 x-small 0 0" variant="icon" icon={IconAudio}>
                <ScreenReaderContent>{I18n.t('Record Audio')}</ScreenReaderContent>
              </Button>
              <Button
                disabled={this.state.commentText.length === 0}
                onClick={() => this.onSendComment(createSubmissionComment)}
              >
                {I18n.t('Send Comment')}
              </Button>
            </div>
          </div>
        )}
      </Mutation>
    )
  }
}
