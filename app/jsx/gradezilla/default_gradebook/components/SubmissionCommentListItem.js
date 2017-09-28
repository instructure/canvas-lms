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
import Avatar from 'instructure-ui/lib/components/Avatar';
import Button from 'instructure-ui/lib/components/Button';
import Link from 'instructure-ui/lib/components/Link';
import IconTrashLine from 'instructure-icons/lib/Line/IconTrashLine';
import Typography from 'instructure-ui/lib/components/Typography';
import DateHelper from 'jsx/shared/helpers/dateHelper';
import TextHelper from 'compiled/str/TextHelper';
import CommentPropTypes from 'jsx/gradezilla/default_gradebook/propTypes/CommentPropTypes';

function handledeleteComment (id, deleteSubmissionComment) {
  return () => {
    const message = I18n.t('Are you sure you want to delete this comment?');
    if(confirm(message)) {
      deleteSubmissionComment(id);
    }
  };
}

export default function SubmissionCommentListItem (props) {
  const {
    author,
    authorAvatarUrl,
    authorUrl ,
    comment,
    createdAt,
    id,
    last,
    deleteSubmissionComment
  } = props;
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', margin: '0 0 0.75rem' }}>
        <div style={{ display: 'flex' }}>
          <Link href={authorUrl}>
            <Avatar
              size="small"
              name={author}
              alt={I18n.t('Avatar for %{author}', { author })}
              src={authorAvatarUrl}
              margin="0 x-small 0 0"
            />
          </Link>

          <div>
            <div style={{ margin: '0 0 0 0.375rem' }}>
              <Typography weight="bold" size="small" lineHeight="fit">
                <Link href={authorUrl}>{TextHelper.truncateText(author, { max: 25 })}</Link>
              </Typography>
            </div>

            <div style={{ margin: '0 0 0 0.375rem' }}>
              <Typography size="small" lineHeight="fit">
                {DateHelper.formatDatetimeForDisplay(createdAt)}
              </Typography>
            </div>
          </div>
        </div>

        <div>
          <Button
            size="small"
            variant="icon"
            onClick={handledeleteComment(id, deleteSubmissionComment)}
          >
            <IconTrashLine title={I18n.t('Delete Comment: %{comment}', { comment })}/>
          </Button>
        </div>
      </div>

      <div>
        <Typography size="small" lineHeight="condensed">
          <p style={{ margin: '0 0 0.75rem' }}>{comment}</p>
        </Typography>
      </div>

      { !last && <hr style={{ margin: '1rem 0', borderTop: 'dashed 0.063rem' }} /> }
    </div>
  );
}

SubmissionCommentListItem.propTypes = {
  ...CommentPropTypes,
  last: bool.isRequired,
  deleteSubmissionComment: func.isRequired
};
