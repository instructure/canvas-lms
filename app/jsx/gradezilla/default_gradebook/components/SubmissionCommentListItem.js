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

import React from 'react';
import { bool, func } from 'prop-types';
import I18n from 'i18n!gradebook';
import Avatar from '@instructure/ui-elements/lib/components/Avatar';
import Button from '@instructure/ui-buttons/lib/components/Button';
import Link from '@instructure/ui-elements/lib/components/Link';
import IconEditLine from '@instructure/ui-icons/lib/Line/IconEdit';
import IconTrashLine from '@instructure/ui-icons/lib/Line/IconTrash';
import Text from '@instructure/ui-elements/lib/components/Text';
import DateHelper from '../../../shared/helpers/dateHelper';
import TextHelper from 'compiled/str/TextHelper';
import CommentPropTypes from '../../../gradezilla/default_gradebook/propTypes/CommentPropTypes';
import SubmissionCommentUpdateForm from '../../../gradezilla/default_gradebook/components/SubmissionCommentUpdateForm';

function submissionCommentDate (date) {
  return DateHelper.formatDatetimeForDisplay(date, 'short');
}

export default class SubmissionCommentListItem extends React.Component {
  static propTypes = {
    ...CommentPropTypes,
    editing: bool.isRequired,
    last: bool.isRequired,
    cancelCommenting: func.isRequired,
    currentUserIsAuthor: bool.isRequired,
    deleteSubmissionComment: func.isRequired,
    editSubmissionComment: func.isRequired,
    updateSubmissionComment: func.isRequired,
    processing: bool.isRequired,
    setProcessing: func.isRequired
  };

  componentDidUpdate (prevProps) {
    if (prevProps.editing && !this.props.editing) {
      this.editButton.focus();
    }
  }

  handleDeleteComment = () => {
    const message = I18n.t('Are you sure you want to delete this comment?');
    if (confirm(message)) {
      this.props.deleteSubmissionComment(this.props.id);
    }
  }

  handleEditComment = () => {
    this.props.editSubmissionComment(this.props.id);
  }

  bindEditButton = (ref) => {
    this.editButton = ref;
  }

  commentBody () {
    if (this.props.editing) {
      return (
        <SubmissionCommentUpdateForm
          cancelCommenting={this.props.cancelCommenting}
          comment={this.props.comment}
          id={this.props.id}
          processing={this.props.processing}
          setProcessing={this.props.setProcessing}
          updateSubmissionComment={this.props.updateSubmissionComment}
        />
      );
    }

    return (
      <div>
        <Text size="small" lineHeight="condensed">
          <p style={{ margin: '0 0 0.75rem' }}>{this.props.comment}</p>
        </Text>
      </div>
    );
  }

  commentTimestamp () {
    const date = submissionCommentDate(this.props.editedAt || this.props.createdAt);
    return this.props.editedAt ? I18n.t('(Edited) %{date}', { date }) : date;
  }

  render () {
    return (
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', margin: '0 0 0.75rem' }}>
          <div style={{ display: 'flex' }}>
            <Link href={this.props.authorUrl}>
              <Avatar
                size="small"
                name={this.props.author}
                alt={I18n.t('Avatar for %{author}', { author: this.props.author })}
                src={this.props.authorAvatarUrl}
                margin="0 x-small 0 0"
              />
            </Link>

            <div>
              <div style={{ margin: '0 0 0 0.375rem' }}>
                <Text weight="bold" size="small" lineHeight="fit">
                  <Link href={this.props.authorUrl}>{TextHelper.truncateText(this.props.author, { max: 22 })}</Link>
                </Text>
              </div>

              <div style={{ margin: '0 0 0 0.375rem' }}>
                <Text size="small" lineHeight="fit">
                  {this.commentTimestamp()}
                </Text>
              </div>
            </div>
          </div>

          <div style={{minWidth: '60px'}}>
            {
              this.props.currentUserIsAuthor &&
                <Button
                  size="small"
                  variant="icon"
                  onClick={this.handleEditComment}
                  buttonRef={this.bindEditButton}
                >
                  <IconEditLine title={I18n.t('Edit Comment: %{comment}', { comment: this.props.comment })}/>
                </Button>
            }
            <span style={{ float: 'right' }}>
              <Button size="small" variant="icon" onClick={this.handleDeleteComment}>
                <IconTrashLine title={I18n.t('Delete Comment: %{comment}', { comment: this.props.comment })}/>
              </Button>
            </span>
          </div>
        </div>

        { this.commentBody() }
        { !this.props.last && <hr style={{ margin: '1rem 0', borderTop: 'dashed 0.063rem' }} /> }
      </div>
    );
  }
}
