/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import $ from 'jquery';
import 'compiled/jquery.rails_flash_notifications';
import React from 'react';
import { bool, func } from 'prop-types';
import I18n from 'i18n!gradebook';
import TextArea from 'instructure-ui/lib/components/TextArea';
import Button from 'instructure-ui/lib/components/Button';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';

function isValid (comment) {
  return comment.trim().length > 0;
}

class SubmissionCommentForm extends React.Component {
  state = { comment: '', textAreaWarning: false };

  handleCommentChange = (event) => {
    const comment = event.target.value;
    const wasInvalid = () => !isValid(this.state.comment);
    const nowValid = () => isValid(comment);
    // only change the warning to false if the comment was invalid and is now valid
    const textAreaWarning = wasInvalid() && nowValid() ? false : this.state.textAreaWarning;
    this.setState({ comment, textAreaWarning });
  }

  handlePostComment = event => {
    event.preventDefault();
    this.props.setProcessing(true);
    if (isValid(this.state.comment)) {
      this.props.createSubmissionComment(this.state.comment)
        .catch(() => this.props.setProcessing(false));
      this.setState({ comment: '' })
    } else {
      this.setState({ textAreaWarning: true }, () => {
        $.screenReaderFlashError(this.messages().map(message => message.text).join(', '));
        this.props.setProcessing(false);
      });
    }
  }

  messages () {
    if (this.state.textAreaWarning) {
      return [{ text: I18n.t('No message present'), type: 'error' }];
    }
    return [];
  }

  render () {
    return (
      <div>
        <div>
          <TextArea
            messages={this.messages()}
            label={<ScreenReaderContent>{I18n.t('Leave a comment')}</ScreenReaderContent>}
            placeholder={I18n.t("Leave a comment")}
            onChange={this.handleCommentChange}
            value={this.state.comment}
          />
        </div>

        <div
          style={{ textAlign: 'right', marginTop: '0rem', border: 'none', padding: '0rem', background: 'transparent' }}
        >
          <Button
            disabled={this.props.processing}
            label={<ScreenReaderContent>{I18n.t('Post Comment')}</ScreenReaderContent>}
            margin="small 0"
            onClick={this.handlePostComment}
            variant="primary"
          >
            {I18n.t("Post")}
          </Button>
        </div>
      </div>
    );
  }
}

SubmissionCommentForm.propTypes = {
  createSubmissionComment: func.isRequired,
  processing: bool.isRequired,
  setProcessing: func.isRequired
};

export default SubmissionCommentForm;
