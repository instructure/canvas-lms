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
import { arrayOf, bool, func, number, shape, string } from 'prop-types';
import I18n from 'i18n!gradebook';
import Avatar from 'instructure-ui/lib/components/Avatar';
import Button from 'instructure-ui/lib/components/Button';
import Container from 'instructure-ui/lib/components/Container';
import Heading from 'instructure-ui/lib/components/Heading';
import Link from 'instructure-ui/lib/components/Link';
import Spinner from 'instructure-ui/lib/components/Spinner';
import Tray from 'instructure-ui/lib/components/Tray';
import Typography from 'instructure-ui/lib/components/Typography';
import IconSpeedGraderLine from 'instructure-icons/lib/Line/IconSpeedGraderLine';
import Carousel from 'jsx/gradezilla/default_gradebook/components/Carousel';
import ComingSoonContent from 'jsx/gradezilla/default_gradebook/components/ComingSoonContent';
import LatePolicyGrade from 'jsx/gradezilla/default_gradebook/components/LatePolicyGrade';
import CommentPropTypes from 'jsx/gradezilla/default_gradebook/propTypes/CommentPropTypes';
import SubmissionCommentListItem from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentListItem';
import SubmissionCommentForm from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentForm';
import SubmissionStatus from 'jsx/gradezilla/default_gradebook/components/SubmissionStatus';
import SubmissionTrayRadioInputGroup from 'jsx/gradezilla/default_gradebook/components/SubmissionTrayRadioInputGroup';

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

function renderTraySubHeading (headingText) {
  return (
    <Heading level="h4" as="h2" margin="auto auto small">
      <Typography weight="bold">
        {headingText}
      </Typography>
    </Heading>
  );
}

function renderSubmissionCommentList (args) {
  return args.submissionComments.map(comment =>
    <SubmissionCommentListItem
      author={comment.author}
      authorUrl={comment.authorUrl}
      authorAvatarUrl={comment.authorAvatarUrl}
      comment={comment.comment}
      createdAt={comment.createdAt}
      id={comment.id}
      key={comment.id}
      last={args.submissionComments[args.submissionComments.length - 1].id === comment.id}
      deleteSubmissionComment={args.deleteSubmissionComment}
    />
  );
}

function renderSubmissionComments (args) {
  const {
    submissionComments,
    submissionCommentsLoaded,
    deleteSubmissionComment,
    createSubmissionComment,
    updateSubmissionComments,
    processing,
    setProcessing
  } = args;

  if(submissionCommentsLoaded) {
    return (
      <div>
        {renderTraySubHeading('Comments')}

        {renderSubmissionCommentList({ submissionComments, submissionCommentsLoaded, deleteSubmissionComment })}

        <SubmissionCommentForm
          createSubmissionComment={createSubmissionComment}
          updateSubmissionComments={updateSubmissionComments}
          processing={processing}
          setProcessing={setProcessing}
        />
      </div>
    );
  }
  return (
    <div style={{ textAlign: 'center' }}>
      <Spinner title={I18n.t('Loading comments')} size="large" />
    </div>
  );
}

export default function SubmissionTray (props) {
  const { name, avatarUrl } = props.student;

  const assignmentParam = `assignment_id=${props.submission.assignmentId}`;
  const studentParam = `#%7B%22student_id%22%3A${props.student.id}%7D`;
  const speedGraderUrl = `/courses/${props.courseId}/gradebook/speed_grader?${assignmentParam}${studentParam}`;

  const submissionCommentsProps = {
    submissionComments: props.submissionComments,
    submissionCommentsLoaded: props.submissionCommentsLoaded,
    deleteSubmissionComment: props.deleteSubmissionComment,
    createSubmissionComment: props.createSubmissionComment,
    updateSubmissionComments: props.updateSubmissionComments,
    processing: props.processing,
    setProcessing: props.setProcessing
  };
  let carouselContainerStyleOverride = '0 0 0 0';

  if (!avatarUrl) {
    // When we don't have an avatar, let's ensure there's enough space between the tray close button and the student
    // carousel's previous student arrow
    carouselContainerStyleOverride = 'small 0 0 0';
  }

  return (
    <Tray
      contentRef={props.contentRef}
      label={I18n.t('Submission tray')}
      closeButtonLabel={I18n.t('Close submission tray')}
      applicationElement={() => document.getElementById('application')}
      open={props.isOpen}
      shouldContainFocus
      placement="end"
      onDismiss={props.onRequestClose}
      onClose={props.onClose}
    >
      <div className="SubmissionTray__Container">
        { props.showContentComingSoon ?
            renderComingSoon(props.speedGraderEnabled, speedGraderUrl) :
            <div id="SubmissionTray__Content" style={{ display: 'flex', flexDirection: 'column' }}>
              <Container as="div" padding={carouselContainerStyleOverride}>
                {avatarUrl && renderAvatar(name, avatarUrl)}

                <Carousel
                  id="student-carousel"
                  disabled={props.processing || !props.submissionCommentsLoaded}
                  displayLeftArrow={!props.isFirstStudent}
                  displayRightArrow={!props.isLastStudent}
                  leftArrowDescription={I18n.t('Previous student')}
                  onLeftArrowClick={props.selectPreviousStudent}
                  onRightArrowClick={props.selectNextStudent}
                  rightArrowDescription={I18n.t('Next student')}
                >
                  <Link href={props.student.gradesUrl}>
                    {name}
                  </Link>
                </Carousel>

                <Container as="div" margin="small 0" className="hr" />

                <Carousel
                  id="assignment-carousel"
                  disabled={props.processing || !props.submissionCommentsLoaded}
                  displayLeftArrow={!props.isFirstAssignment}
                  displayRightArrow={!props.isLastAssignment}
                  leftArrowDescription={I18n.t('Previous assignment')}
                  onLeftArrowClick={props.selectPreviousAssignment}
                  onRightArrowClick={props.selectNextAssignment}
                  rightArrowDescription={I18n.t('Next assignment')}
                >
                  <Link href={props.assignment.htmlUrl}>
                    {props.assignment.name}
                  </Link>
                </Carousel>

                { props.speedGraderEnabled && renderSpeedGraderLink(speedGraderUrl) }

                <Container as="div" margin="small 0" className="hr" />
              </Container>

              <Container as="div" style={{ overflowY: 'auto', flex: '1 1 auto' }}>
                <SubmissionStatus
                  assignment={props.assignment}
                  submission={props.submission}
                  isInOtherGradingPeriod={props.isInOtherGradingPeriod}
                  isInClosedGradingPeriod={props.isInClosedGradingPeriod}
                  isInNoGradingPeriod={props.isInNoGradingPeriod}
                />

                {!!props.submission.pointsDeducted &&
                  <div>
                    <LatePolicyGrade submission={props.submission} />

                    <Container as="div" margin="small 0" className="hr" />
                  </div>
                }

                <Container as="div" id="SubmissionTray__RadioInputGroup" margin="0 0 small 0">
                  <SubmissionTrayRadioInputGroup
                    colors={props.colors}
                    locale={props.locale}
                    latePolicy={props.latePolicy}
                    submission={props.submission}
                    submissionUpdating={props.submissionUpdating}
                    updateSubmission={props.updateSubmission}
                  />
                </Container>

                <Container as="div" margin="small 0" className="hr" />

                <Container as="div" id="SubmissionTray__Comments" padding="xx-small">
                  {renderSubmissionComments(submissionCommentsProps)}
                </Container>
              </Container>
            </div>
        }
      </div>
    </Tray>
  );
}

SubmissionTray.defaultProps = {
  contentRef: undefined,
  latePolicy: { lateSubmissionInterval: 'day' },
  submission: { drop: false }
};

SubmissionTray.propTypes = {
  assignment: shape({
    name: string.isRequired,
    htmlUrl: string.isRequired,
    muted: bool.isRequired,
    published: bool.isRequired
  }).isRequired,
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
    avatarUrl: string,
    gradesUrl: string.isRequired
  }).isRequired,
  submission: shape({
    drop: bool,
    excused: bool.isRequired,
    grade: string,
    late: bool.isRequired,
    missing: bool.isRequired,
    pointsDeducted: number,
    secondsLate: number.isRequired,
    assignmentId: string.isRequired
  }),
  isFirstAssignment: bool.isRequired,
  isLastAssignment: bool.isRequired,
  selectNextAssignment: func.isRequired,
  selectPreviousAssignment: func.isRequired,
  isFirstStudent: bool.isRequired,
  isLastStudent: bool.isRequired,
  selectNextStudent: func.isRequired,
  selectPreviousStudent: func.isRequired,
  courseId: string.isRequired,
  speedGraderEnabled: bool.isRequired,
  submissionUpdating: bool.isRequired,
  updateSubmission: func.isRequired,
  locale: string.isRequired,
  latePolicy: shape({
    lateSubmissionInterval: string
  }).isRequired,
  submissionComments: arrayOf(shape(CommentPropTypes).isRequired).isRequired,
  submissionCommentsLoaded: bool.isRequired,
  createSubmissionComment: func.isRequired,
  deleteSubmissionComment: func.isRequired,
  updateSubmissionComments: func.isRequired,
  processing: bool.isRequired,
  setProcessing: func.isRequired,
  isInOtherGradingPeriod: bool.isRequired,
  isInClosedGradingPeriod: bool.isRequired,
  isInNoGradingPeriod: bool.isRequired
};
