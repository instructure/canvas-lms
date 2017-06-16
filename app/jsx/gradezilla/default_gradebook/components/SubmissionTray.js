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
import SubmissionTrayRadioInputGroup from 'jsx/gradezilla/default_gradebook/components/SubmissionTrayRadioInputGroup';
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

export default function SubmissionTray (props) {
  const { name, avatarUrl } = props.student;
  return (
    <Tray
      contentRef={props.contentRef}
      label={I18n.t('Submission tray')}
      isDismissable
      closeButtonLabel={I18n.t('Close submission tray')}
      isOpen={props.isOpen}
      trapFocus
      placement="end"
      onRequestClose={props.onRequestClose}
      onClose={props.onClose}
    >
      <div className="SubmissionTray__Container">
        {
          props.showContentComingSoon ?
            <ComingSoonContent /> :
            <div>
              <div id="SubmissionTray__Content">
                {avatarUrl && renderAvatar(name, avatarUrl)}

                <div id="SubmissionTray__StudentName">
                  {name}
                </div>

                {!!props.submission.pointsDeducted && <LatePolicyGrade submission={props.submission} />}

                <div id="SubmissionTray__RadioInputGroup">
                  <SubmissionTrayRadioInputGroup
                    colors={props.colors}
                    locale={props.locale}
                    latePolicy={props.latePolicy}
                    submission={props.submission}
                  />
                </div>
              </div>
            </div>
        }
      </div>
    </Tray>
  );
}

SubmissionTray.defaultProps = {
  contentRef: undefined,
  latePolicy: { lateSubmissionInterval: 'day' }
}

SubmissionTray.propTypes = {
  contentRef: func,
  isOpen: bool.isRequired,
  colors: shape({
    late: string.isRequired,
    missing: string.isRequired,
    excused: string.isRequired
  }).isRequired,
  onClose: func.isRequired,
  onRequestClose: func.isRequired,
  showContentComingSoon: bool.isRequired,
  student: shape({
    name: string.isRequired,
    avatarUrl: string
  }).isRequired,
  submission: shape({
    excused: bool.isRequired,
    grade: string,
    late: bool.isRequired,
    missing: bool.isRequired,
    pointsDeducted: number,
    secondsLate: number.isRequired
  }),
  locale: string.isRequired,
  latePolicy: shape({
    lateSubmissionInterval: string
  }).isRequired
};
