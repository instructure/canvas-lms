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
import Avatar from 'instructure-ui/lib/components/Avatar';
import Button from 'instructure-ui/lib/components/Button';
import Container from 'instructure-ui/lib/components/Container';
import Tray from 'instructure-ui/lib/components/Tray';
import IconSpeedGraderLine from 'instructure-icons/lib/Line/IconSpeedGraderLine';
import I18n from 'i18n!gradebook';

function renderAvatar (name, avatarUrl) {
  return (
    <div id="SubmissionTray__Avatar">
      <Avatar name={name} src={avatarUrl} size="auto" />
    </div>
  );
}

function renderSpeedGraderLink (speedGraderUrl) {
  return (
    <Container as="div" textAlign="center">
      <Button href={speedGraderUrl} variant="link">
        <IconSpeedGraderLine />
        {I18n.t('SpeedGrader')}
      </Button>
    </Container>
  );
}

function renderComingSoon (speedGraderEnabled, speedGraderUrl) {
  return (
    <div>
      { speedGraderEnabled && renderSpeedGraderLink(speedGraderUrl) }
      <ComingSoonContent />
    </div>
  );
}

export default function SubmissionTray (props) {
  const { name, avatarUrl } = props.student;
  const speedGraderUrl = `/courses/${props.courseId}/gradebook/speed_grader?assignment_id=${props.submission.assignmentId}#%7B%22student_id%22%3A${props.student.id}%7D`;
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
            renderComingSoon(props.speedGraderEnabled, speedGraderUrl) :
            <div>
              <div id="SubmissionTray__Content">
                {avatarUrl && renderAvatar(name, avatarUrl)}

                <div id="SubmissionTray__StudentName">
                  {name}
                </div>

                { props.speedGraderEnabled && renderSpeedGraderLink(speedGraderUrl) }

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
    id: string.isRequired,
    name: string.isRequired,
    avatarUrl: string
  }).isRequired,
  submission: shape({
    excused: bool.isRequired,
    grade: string,
    late: bool.isRequired,
    missing: bool.isRequired,
    pointsDeducted: number,
    secondsLate: number.isRequired,
    assignmentId: string.isRequired
  }),
  courseId: string.isRequired,
  speedGraderEnabled: bool.isRequired,
  locale: string.isRequired,
  latePolicy: shape({
    lateSubmissionInterval: string
  }).isRequired
};
