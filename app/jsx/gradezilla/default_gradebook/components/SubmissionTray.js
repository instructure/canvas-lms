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
import { bool, func, number, shape, string } from 'prop-types';
import ComingSoonContent from 'jsx/gradezilla/default_gradebook/components/ComingSoonContent';
import LatePolicyGrade from 'jsx/gradezilla/default_gradebook/components/LatePolicyGrade';
import Tray from 'instructure-ui/lib/components/Tray';
import Avatar from 'instructure-ui/lib/components/Avatar';
import I18n from 'i18n!gradebook';

function renderAvatar (name, avatarUrl) {
  return (
    <div id="SubmissionTray__Avatar">
      <Avatar name={name} src={avatarUrl} size="auto" />
    </div>
  );
}

function renderTrayContent (showContentComingSoon, student, submission) {
  if (showContentComingSoon) {
    return (<ComingSoonContent />);
  }

  const { name, avatarUrl } = student;

  return (
    <div id="SubmissionTray__Content">
      {avatarUrl && renderAvatar(name, avatarUrl)}
      <div id="SubmissionTray__StudentName">
        {name}
      </div>

      {!!submission.pointsDeducted && <LatePolicyGrade submission={submission} />}
    </div>
  );
}

export default function SubmissionTray (props) {
  const { showContentComingSoon, student, submission } = props;

  return (
    <Tray
      contentRef={props.contentRef}
      label={I18n.t('Submission tray')}
      dismissable
      closeButtonLabel={I18n.t('Close submission tray')}
      isOpen={props.isOpen}
      trapFocus
      placement="end"
      onRequestClose={props.onRequestClose}
      onClose={props.onClose}
    >
      <div className="SubmissionTray__Container">
        {renderTrayContent(showContentComingSoon, student, submission)}
      </div>
    </Tray>
  );
}

SubmissionTray.defaultProps = {
  contentRef: undefined
}

SubmissionTray.propTypes = {
  contentRef: func,
  isOpen: bool.isRequired,
  onClose: func.isRequired,
  onRequestClose: func.isRequired,
  showContentComingSoon: bool.isRequired,
  student: shape({
    name: string.isRequired,
    avatarUrl: string
  }).isRequired,
  submission: shape({
    grade: string,
    pointsDeducted: number
  }).isRequired
};
