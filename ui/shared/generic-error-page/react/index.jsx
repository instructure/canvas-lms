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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'

import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import axios from '@canvas/axios'
import {string} from 'prop-types'

import ErrorTextInputForm from './ErrorTextInputForm'
import ErrorPageHeader from './ErrorPageHeader'

const I18n = useI18nScope('generic_error_page')

/*
 * A component that can be used to render an error page
 * with a error report comment box
 *
 * The submission comment box enables a user to log a report
 * to our errors_controller endpoint to explain how the
 * error occured
 */
export default class GenericErrorPage extends React.Component {
  static propTypes = {
    errorSubject: string,
    errorCategory: string,
    errorMessage: string,
    imageUrl: string.isRequired,
    stack: string,
  }

  static defaultProps = {
    errorSubject: 'No Error Subject',
    errorCategory: 'No Error Category',
    errorMessage: 'No Error Message',
  }

  state = {
    showingCommentBox: false,
    commentPosted: false,
    commentPostError: false,
    submitLoading: false,
    email: '',
    textAreaComment: '',
  }

  handleOpenCommentBox = () => {
    // Only allow user to post a comment once
    this.setState({showingCommentBox: true})
  }

  handleChangeCommentBox = event => {
    this.setState({textAreaComment: event.target.value})
  }

  handleChangeEmail = event => {
    this.setState({email: event.target.value})
  }

  // Submit makes a post to the create method used in the errors_controller.rb
  // The create method has detailed documentation on what each parameter means
  handleSubmitErrorReport = async () => {
    const postData = {
      error: {
        subject: this.props.errorSubject,
        category: this.props.errorCategory,
        message: this.props.errorMessage,
        url: window.location.href,
        comments: this.state.textAreaComment,
        email: this.state.email,
        backtrace: this.props.stack,
      },
    }
    this.setState({submitLoading: true, showingCommentBox: false})
    try {
      // Returns json of {logged: boolean, id: string}
      const request = await axios.post('/error_reports', postData, {
        headers: {'content-type': 'application/json'},
      })
      const logObject = request.data
      if (logObject.logged) {
        this.setState({commentPosted: true, submitLoading: false})
      } else {
        this.setState({commentPosted: true, commentPostError: true, submitLoading: false})
      }
    } catch (err) {
      this.setState({commentPosted: true, commentPostError: true, submitLoading: false})
    }
  }

  render() {
    return (
      <View
        as="div"
        width="100%"
        height="100%"
        margin="large auto"
        textAlign="center"
        display="block"
      >
        <ErrorPageHeader imageUrl={this.props.imageUrl} />
        <View margin="small" display="block">
          {!this.state.commentPosted && (
            <>
              <View margin="small" display="block">
                <Text margin="0">{I18n.t('Help us improve by telling us what happened')}</Text>
              </View>
              <View margin="small" display="block">
                <Button margin="0" color="primary" onClick={this.handleOpenCommentBox}>
                  {I18n.t('Report Issue')}
                </Button>
              </View>
            </>
          )}
          {this.state.showingCommentBox && (
            <ErrorTextInputForm
              textAreaComment={this.state.textAreaComment}
              email={this.state.email}
              handleChangeCommentBox={this.handleChangeCommentBox}
              handleChangeEmail={this.handleChangeEmail}
              handleSubmitErrorReport={this.handleSubmitErrorReport}
            />
          )}
          {this.state.submitLoading && (
            <Spinner renderTitle={I18n.t('Loading')} margin="0 0 0 medium" />
          )}
          {this.state.commentPosted && this.state.commentPostError && (
            <View display="block" data-testid="generic-error-comments-submitted">
              <Text color="danger" margin="x-small">
                {I18n.t('Comment failed to post! Please try again later.')}
              </Text>
            </View>
          )}
          {this.state.commentPosted && !this.state.commentPostError && (
            <View display="block" data-testid="generic-error-comments-submitted">
              <Text margin="x-small">{I18n.t('Comment submitted!')}</Text>
            </View>
          )}
        </View>
      </View>
    )
  }
}
