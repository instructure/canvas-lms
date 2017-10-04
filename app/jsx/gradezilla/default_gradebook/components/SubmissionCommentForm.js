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
import { bool, func, string } from 'prop-types';
import I18n from 'i18n!gradebook';
import TextArea from 'instructure-ui/lib/components/TextArea';
import Button from 'instructure-ui/lib/components/Button';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';

class SubmissionCommentForm extends React.Component {
  static propTypes = {
    comment: string,
    processing: bool.isRequired,
    setProcessing: func.isRequired
  };

  static defaultProps = {
    comment: ''
  };

  constructor (props) {
    super(props);
    this.bindTextarea = this.bindTextarea.bind(this);
    this.handleCommentChange = this.handleCommentChange.bind(this);
    this.handlePublishComment = this.handlePublishComment.bind(this);
    this.state = { comment: props.comment };
  }

  handleCommentChange (event) {
    this.setState({ comment: event.target.value });
  }

  handlePublishComment (event) {
    event.preventDefault();
    this.props.setProcessing(true);
    this.publishComment().catch(() => this.props.setProcessing(false));
  }

  commentIsValid () {
    const comment = this.state.comment.trim();
    return comment.length > 0;
  }

  bindTextarea (ref) {
    this.textarea = ref;
  }

  render () {
    const { submitButtonLabel } = this.buttonLabels();
    return (
      <div>
        <div>
          <TextArea
            label={<ScreenReaderContent>{I18n.t('Leave a comment')}</ScreenReaderContent>}
            placeholder={I18n.t("Leave a comment")}
            onChange={this.handleCommentChange}
            value={this.state.comment}
            textareaRef={this.bindTextarea}
          />
        </div>

        {
          this.showButtons() &&
            <div
              style={{ textAlign: 'right', marginTop: '0rem', border: 'none', padding: '0rem', background: 'transparent' }}
            >
              <Button
                disabled={this.props.processing || !this.commentIsValid()}
                label={submitButtonLabel}
                margin="small 0"
                onClick={this.handlePublishComment}
                variant="primary"
              >
                {I18n.t("Submit")}
              </Button>
            </div>
        }
      </div>
    );
  }
}

export default SubmissionCommentForm;
