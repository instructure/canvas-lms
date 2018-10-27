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
import { arrayOf, bool, func, number, oneOf, shape, string } from 'prop-types';
import I18n from 'i18n!gradebook';
import Avatar from '@instructure/ui-elements/lib/components/Avatar';
import Button from '@instructure/ui-buttons/lib/components/Button';
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import View from '@instructure/ui-layout/lib/components/View';
import Heading from '@instructure/ui-elements/lib/components/Heading';
import Link from '@instructure/ui-elements/lib/components/Link';
import Spinner from '@instructure/ui-elements/lib/components/Spinner';
import Tray from '@instructure/ui-overlays/lib/components/Tray';
import Text from '@instructure/ui-elements/lib/components/Text';
import IconSpeedGraderLine from '@instructure/ui-icons/lib/Line/IconSpeedGrader';
import Carousel from '../../../gradezilla/default_gradebook/components/Carousel';
import GradeInput from '../../../gradezilla/default_gradebook/components/GradeInput';
import LatePolicyGrade from '../../../gradezilla/default_gradebook/components/LatePolicyGrade';
import CommentPropTypes from '../../../gradezilla/default_gradebook/propTypes/CommentPropTypes';
import SubmissionCommentListItem from '../../../gradezilla/default_gradebook/components/SubmissionCommentListItem';
import SubmissionCommentCreateForm from '../../../gradezilla/default_gradebook/components/SubmissionCommentCreateForm';
import SubmissionStatus from '../../../gradezilla/default_gradebook/components/SubmissionStatus';
import SubmissionTrayRadioInputGroup from '../../../gradezilla/default_gradebook/components/SubmissionTrayRadioInputGroup';

function renderAvatar (name, avatarUrl) {
  return (
    <div id="SubmissionTray__Avatar">
      <Avatar name={name} src={avatarUrl} size="auto" />
    </div>
  );
}

function renderTraySubHeading (headingText) {
  return (
    <Heading level="h4" as="h2" margin="auto auto small">
      <Text weight="bold">
        {headingText}
      </Text>
    </Heading>
  );
}

export default class SubmissionTray extends React.Component {
  static defaultProps = {
    contentRef: undefined,
    gradingDisabled: false,
    latePolicy: { lateSubmissionInterval: 'day' },
    submission: { drop: false },
    pendingGradeInfo: null,
  };

  static propTypes = {
    assignment: shape({
      name: string.isRequired,
      htmlUrl: string.isRequired,
      muted: bool.isRequired,
      published: bool.isRequired,
      anonymizeStudents: bool.isRequired,
      moderatedGrading: bool.isRequired,
    }).isRequired,
    contentRef: func,
    currentUserId: string.isRequired,
    editedCommentId: string,
    editSubmissionComment: func.isRequired,
    enterGradesAs: oneOf(['points', 'percent', 'passFail', 'gradingScheme']).isRequired,
    gradingScheme: arrayOf(Array).isRequired,
    gradingDisabled: bool,
    isOpen: bool.isRequired,
    colors: shape({
      late: string.isRequired,
      missing: string.isRequired,
      excused: string.isRequired
    }).isRequired,
    onClose: func.isRequired,
    onGradeSubmission: func.isRequired,
    onRequestClose: func.isRequired,
    pendingGradeInfo: shape({
      excused: bool.isRequired,
      grade: string,
      valid: bool.isRequired
    }),
    student: shape({
      id: string.isRequired,
      avatarUrl: string,
      gradesUrl: string.isRequired,
      isConcluded: bool.isRequired,
      name: string.isRequired
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
    updateSubmissionComment: func.isRequired,
    locale: string.isRequired,
    latePolicy: shape({
      lateSubmissionInterval: string
    }).isRequired,
    submissionComments: arrayOf(shape(CommentPropTypes).isRequired).isRequired,
    submissionCommentsLoaded: bool.isRequired,
    createSubmissionComment: func.isRequired,
    deleteSubmissionComment: func.isRequired,
    processing: bool.isRequired,
    setProcessing: func.isRequired,
    isInOtherGradingPeriod: bool.isRequired,
    isInClosedGradingPeriod: bool.isRequired,
    isInNoGradingPeriod: bool.isRequired,
    isNotCountedForScore: bool.isRequired,
    onAnonymousSpeedGraderClick: func.isRequired
  };

  cancelCommenting = () => {
    this.props.editSubmissionComment(null);
  };

  renderSubmissionCommentList () {
    return this.props.submissionComments.map(comment => (
      <SubmissionCommentListItem
        author={comment.author}
        cancelCommenting={this.cancelCommenting}
        currentUserIsAuthor={this.props.currentUserId === comment.authorId}
        authorUrl={comment.authorUrl}
        authorAvatarUrl={comment.authorAvatarUrl}
        comment={comment.comment}
        createdAt={comment.createdAt}
        editedAt={comment.editedAt}
        editing={!!this.props.editedCommentId && this.props.editedCommentId === comment.id}
        id={comment.id}
        key={comment.id}
        last={this.props.submissionComments[this.props.submissionComments.length - 1].id === comment.id}
        deleteSubmissionComment={this.props.deleteSubmissionComment}
        editSubmissionComment={this.props.editSubmissionComment}
        updateSubmissionComment={this.props.updateSubmissionComment}
        processing={this.props.processing}
        setProcessing={this.props.setProcessing}
      />
    ));
  }

  renderSubmissionComments () {
    const {anonymizeStudents, moderatedGrading, muted} = this.props.assignment;
    if (anonymizeStudents || (moderatedGrading && muted)) {
      return;
    }

    if (this.props.submissionCommentsLoaded) {
      return (
        <div>
          {renderTraySubHeading(I18n.t('Comments'))}

          {this.renderSubmissionCommentList()}

          {
            !this.props.editedCommentId &&
              <SubmissionCommentCreateForm
                cancelCommenting={this.cancelCommenting}
                createSubmissionComment={this.props.createSubmissionComment}
                processing={this.props.processing}
                setProcessing={this.props.setProcessing}
              />
          }
        </div>
      );
    }

    return (
      <div style={{ textAlign: 'center' }}>
        <Spinner title={I18n.t('Loading comments')} size="large" />
      </div>
    );
  }

  renderSpeedGraderLink (speedGraderProps) {
    const buttonProps = { variant: 'link', href: speedGraderProps.speedGraderUrl }
    if (speedGraderProps.anonymizeStudents) {
      buttonProps.onClick = (e) => {
        e.preventDefault();
        this.props.onAnonymousSpeedGraderClick(speedGraderProps.speedGraderUrl);
      };
    }
    return (
      <View as="div" textAlign="center">
        <Button {...buttonProps}>
          <IconSpeedGraderLine />
          {I18n.t('SpeedGrader')}
        </Button>
      </View>
    );
  }

  render () {
    const { name, avatarUrl } = this.props.student;
    const assignmentParam = `assignment_id=${this.props.submission.assignmentId}`;
    const studentParam = `#{"student_id":"${this.props.student.id}"}`;
    const speedGraderUrlParams = this.props.assignment.anonymizeStudents
      ? assignmentParam
      : `${assignmentParam}${studentParam}`
    const speedGraderUrl = encodeURI(`/courses/${this.props.courseId}/gradebook/speed_grader?${speedGraderUrlParams}`)

    const submissionCommentsProps = {
      submissionComments: this.props.submissionComments,
      submissionCommentsLoaded: this.props.submissionCommentsLoaded,
      deleteSubmissionComment: this.props.deleteSubmissionComment,
      createSubmissionComment: this.props.createSubmissionComment,
      processing: this.props.processing,
      setProcessing: this.props.setProcessing,
    };
    const trayIsBusy = this.props.processing || this.props.submissionUpdating || !this.props.submissionCommentsLoaded;

    let carouselContainerStyleOverride = '0 0 0 0';

    if (!avatarUrl) {
      // When we don't have an avatar, let's ensure there's enough space between the tray close button and the student
      // carousel's previous student arrow
      carouselContainerStyleOverride = 'small 0 0 0';
    }

    let speedGraderProps = null;
    if (this.props.speedGraderEnabled) {
      speedGraderProps = {
        anonymizeStudents: this.props.assignment.anonymizeStudents,
        speedGraderUrl
      };
    }

    return (
      <Tray
        contentRef={this.props.contentRef}
        label={I18n.t('Submission tray')}
        open={this.props.isOpen}
        shouldContainFocus
        placement="end"
        onDismiss={this.props.onRequestClose}
        onClose={this.props.onClose}
      >
        <CloseButton placement="start" onClick={this.props.onRequestClose}>
          {I18n.t('Close submission tray')}
        </CloseButton>
        <div className="SubmissionTray__Container">
          <div id="SubmissionTray__Content" style={{ display: 'flex', flexDirection: 'column' }}>
            <View as="div" padding={carouselContainerStyleOverride}>
              {avatarUrl && renderAvatar(name, avatarUrl)}

              <Carousel
                id="student-carousel"
                disabled={trayIsBusy}
                displayLeftArrow={!this.props.isFirstStudent}
                displayRightArrow={!this.props.isLastStudent}
                leftArrowDescription={I18n.t('Previous student')}
                onLeftArrowClick={this.props.selectPreviousStudent}
                onRightArrowClick={this.props.selectNextStudent}
                rightArrowDescription={I18n.t('Next student')}
              >
                <Link href={this.props.student.gradesUrl}>
                  {name}
                </Link>
              </Carousel>

              <View as="div" margin="small 0" className="hr" />

              <Carousel
                id="assignment-carousel"
                disabled={trayIsBusy}
                displayLeftArrow={!this.props.isFirstAssignment}
                displayRightArrow={!this.props.isLastAssignment}
                leftArrowDescription={I18n.t('Previous assignment')}
                onLeftArrowClick={this.props.selectPreviousAssignment}
                onRightArrowClick={this.props.selectNextAssignment}
                rightArrowDescription={I18n.t('Next assignment')}
              >
                <Link href={this.props.assignment.htmlUrl}>
                  {this.props.assignment.name}
                </Link>
              </Carousel>

              { this.props.speedGraderEnabled && this.renderSpeedGraderLink(speedGraderProps) }

              <View as="div" margin="small 0" className="hr" />
            </View>

            <View as="div" style={{ overflowY: 'auto', flex: '1 1 auto' }}>
              <SubmissionStatus
                assignment={this.props.assignment}
                isConcluded={this.props.student.isConcluded}
                isInOtherGradingPeriod={this.props.isInOtherGradingPeriod}
                isInClosedGradingPeriod={this.props.isInClosedGradingPeriod}
                isInNoGradingPeriod={this.props.isInNoGradingPeriod}
                isNotCountedForScore={this.props.isNotCountedForScore}
                submission={this.props.submission}
              />

              <GradeInput
                assignment={this.props.assignment}
                disabled={this.props.gradingDisabled}
                enterGradesAs={this.props.enterGradesAs}
                gradingScheme={this.props.gradingScheme}
                pendingGradeInfo={this.props.pendingGradeInfo}
                onSubmissionUpdate={this.props.onGradeSubmission}
                submission={this.props.submission}
                submissionUpdating={this.props.submissionUpdating}
              />

              {!!this.props.submission.pointsDeducted &&
                <View as="div" margin="small 0 0 0">
                  <LatePolicyGrade
                    assignment={this.props.assignment}
                    enterGradesAs={this.props.enterGradesAs}
                    gradingScheme={this.props.gradingScheme}
                    submission={this.props.submission}
                  />
                </View>
              }

              <View as="div" margin="small 0" className="hr" />

              <View as="div" id="SubmissionTray__RadioInputGroup" margin="0 0 small 0">
                <SubmissionTrayRadioInputGroup
                  colors={this.props.colors}
                  disabled={this.props.gradingDisabled}
                  locale={this.props.locale}
                  latePolicy={this.props.latePolicy}
                  submission={this.props.submission}
                  submissionUpdating={this.props.submissionUpdating}
                  updateSubmission={this.props.updateSubmission}
                />
              </View>

              <View as="div" margin="small 0" className="hr" />

              <View as="div" id="SubmissionTray__Comments" padding="xx-small">
                {this.renderSubmissionComments(submissionCommentsProps)}
              </View>
            </View>
          </div>
        </div>
      </Tray>
    );
  }
}
