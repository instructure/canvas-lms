// @ts-nocheck
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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ApolloProvider, createClient} from '@canvas/apollo'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'
import {InstUISettingsProvider} from '@instructure/emotion'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Avatar} from '@instructure/ui-avatar'
import {Spinner} from '@instructure/ui-spinner'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Tray} from '@instructure/ui-tray'
import {IconSpeedGraderLine} from '@instructure/ui-icons'
import Carousel from './Carousel'
import GradeInput from './GradeInput'
import LatePolicyGrade from './LatePolicyGrade'
import SimilarityScore from './SimilarityScore'
import SubmissionCommentListItem from './SubmissionCommentListItem'
import SubmissionCommentCreateForm from './SubmissionCommentCreateForm'
import SubmissionStatus from './SubmissionStatus'
import SubmissionTrayRadioInputGroup from './SubmissionTrayRadioInputGroup'
import ProxyUploadModal from '@canvas/proxy-submission/react/ProxyUploadModal'
import {extractSimilarityInfo} from '@canvas/grading/SubmissionHelper'
import type {
  GradingStandard,
  LatePolicyCamelized,
  PendingGradeInfo,
  SerializedComment,
} from '../gradebook.d'
import {
  CamelizedAssignment,
  CamelizedSubmission,
  GradeEntryMode,
  GradeResult,
} from '@canvas/grading/grading.d'

import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('gradebook')

function renderAvatar(name: string, avatarUrl: string) {
  return (
    <div id="SubmissionTray__Avatar">
      <Avatar name={name} src={avatarUrl} size="auto" data-fs-exclude={true} />
    </div>
  )
}

function renderTraySubHeading(headingText: string) {
  return (
    <Heading level="h4" as="h2" margin="auto auto small">
      <Text weight="bold">{headingText}</Text>
    </Heading>
  )
}

export type SubmissionTrayProps = {
  assignment: CamelizedAssignment
  currentUserId: string
  editedCommentId: string | null
  gradingDisabled: boolean
  pendingGradeInfo: null | PendingGradeInfo
  isFirstAssignment: boolean
  isLastAssignment: boolean
  colors: {
    late: string
    missing: string
    excused: string
    extended: string
  }
  student: {
    id: string
    avatarUrl?: string | null
    gradesUrl: string
    isConcluded: boolean
    name: string | null
  }
  submission: CamelizedSubmission
  courseId: string
  speedGraderEnabled: boolean
  submissionUpdating: boolean
  submissionCommentsLoaded: boolean
  processing: boolean
  isInOtherGradingPeriod: boolean
  isInClosedGradingPeriod: boolean
  isInNoGradingPeriod: boolean
  isNotCountedForScore: boolean
  enterGradesAs: GradeEntryMode
  isOpen: boolean
  isFirstStudent: boolean
  isLastStudent: boolean
  latePolicy?: LatePolicyCamelized
  locale: string
  editSubmissionComment: (commentId: string | null) => void
  onClose: () => void
  requireStudentGroupForSpeedGrader: boolean
  gradingScheme: null | GradingStandard[]
  onGradeSubmission: (submission: CamelizedSubmission, gradeInfo: GradeResult) => void
  onRequestClose: () => void
  selectNextAssignment: () => void
  selectPreviousAssignment: () => void
  selectNextStudent: () => void
  selectPreviousStudent: () => void
  updateSubmission: (submission: CamelizedSubmission) => void
  updateSubmissionComment: (commentId: string, comment: string) => void
  createSubmissionComment: (comment: string) => void
  deleteSubmissionComment: (commentId: string) => void
  setProcessing: (processing: boolean) => void
  onAnonymousSpeedGraderClick: (speedGraderUrl: string) => void
  submissionComments: SerializedComment[]
  showSimilarityScore: boolean
  proxySubmissionsAllowed: boolean
  reloadSubmission: (student: any, submission: any, proxyDetails: any) => void
  customGradeStatuses: GradeStatus[]
  customGradeStatusesEnabled: boolean
  contentRef?: React.RefObject<HTMLDivElement>
}

type SubmissionTrayState = {
  proxyUploadModalOpen: boolean
}

export default class SubmissionTray extends React.Component<
  SubmissionTrayProps,
  SubmissionTrayState
> {
  static defaultProps = {
    gradingDisabled: false,
    latePolicy: {lateSubmissionInterval: 'day'},
    submission: {drop: false},
    pendingGradeInfo: null,
  }

  state = {
    proxyUploadModalOpen: false,
  }

  cancelCommenting = () => {
    this.props.editSubmissionComment(null)
  }

  renderSubmissionCommentList() {
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
        last={
          this.props.submissionComments[this.props.submissionComments.length - 1].id === comment.id
        }
        deleteSubmissionComment={this.props.deleteSubmissionComment}
        editSubmissionComment={this.props.editSubmissionComment}
        updateSubmissionComment={this.props.updateSubmissionComment}
        processing={this.props.processing}
        setProcessing={this.props.setProcessing}
      />
    ))
  }

  renderSubmissionComments(_props) {
    // TODO: Remove _props? It is not used.
    const {anonymizeStudents, moderatedGrading, muted} = this.props.assignment
    if (anonymizeStudents || (moderatedGrading && muted)) {
      return
    }

    if (this.props.submissionCommentsLoaded) {
      return (
        <div>
          {renderTraySubHeading(I18n.t('Comments'))}

          {this.renderSubmissionCommentList()}

          {!this.props.editedCommentId && (
            <SubmissionCommentCreateForm
              cancelCommenting={this.cancelCommenting}
              createSubmissionComment={this.props.createSubmissionComment}
              processing={this.props.processing}
              setProcessing={this.props.setProcessing}
            />
          )}
        </div>
      )
    }

    return (
      <div style={{textAlign: 'center'}}>
        <Spinner renderTitle={I18n.t('Loading comments')} size="large" />
      </div>
    )
  }

  renderSpeedGraderLink(speedGraderProps) {
    const buttonProps: {
      disabled?: boolean
      href: string
      variant: 'link'
      onClick?: (event: React.MouseEvent) => void
    } = {
      disabled: speedGraderProps.requireStudentGroup,
      href: speedGraderProps.speedGraderUrl,
      variant: 'link', // TODO: replace since this is deprecated with InstUI 8
    }
    if (speedGraderProps.anonymizeStudents) {
      buttonProps.onClick = e => {
        e.preventDefault()
        this.props.onAnonymousSpeedGraderClick(speedGraderProps.speedGraderUrl)
      }
    }

    return (
      <View as="div">
        {speedGraderProps.requireStudentGroup && (
          <Alert variant="info">
            <Text as="p" weight="bold">
              {I18n.t('Select Student Group')}
            </Text>

            <Text as="p">
              {I18n.t(`
                Due to the size of your course you must select a student group before launching
                SpeedGrader.
              `)}
            </Text>
          </Alert>
        )}
        <View as="div" textAlign="center">
          <Button {...buttonProps}>
            <IconSpeedGraderLine />
            {I18n.t('SpeedGrader')}
          </Button>
        </View>
      </View>
    )
  }

  renderSubmitForStudentLink() {
    const {proxySubmissionsAllowed} = this.props
    const isFileUploadAssignment = this.props.assignment?.submissionTypes?.includes('online_upload')
    if (proxySubmissionsAllowed && isFileUploadAssignment) {
      return (
        <View as="div" textAlign="center">
          <Button
            variant="link"
            onClick={this.toggleUploadModal}
            aria-label={I18n.t('Submit for Student %{name}', {name: this.props.student.name})}
            data-testid="submit-for-student-button"
          >
            {I18n.t('Submit for Student')}
          </Button>
        </View>
      )
    }
  }

  renderProxySubmissionIndicator() {
    const {submission} = this.props
    if (submission.proxySubmitter) {
      return (
        <View as="div" textAlign="center">
          <Text data-testid="proxy_submitter_name">
            {I18n.t('Submitted by %{submitter}', {submitter: submission.proxySubmitter})}
          </Text>
          <br />
          <FriendlyDatetime
            format={I18n.t('#date.formats.date_at_time')}
            dateTime={submission.submittedAt}
          />
        </View>
      )
    }
  }

  closeUploadModal = () => {
    this.setState({proxyUploadModalOpen: false})
  }

  toggleUploadModal = () => {
    this.setState(prevState => {
      return {proxyUploadModalOpen: !prevState.proxyUploadModalOpen}
    })
  }

  renderSimilarityScore() {
    const {assignment, submission} = this.props
    const similarityInfo = extractSimilarityInfo(submission)
    if (assignment.anonymizeStudents || similarityInfo == null) {
      return
    }

    const {
      id: entryId,
      data: {similarity_score, status},
    } = similarityInfo.entries[0]
    const reportType = similarityInfo.type
    const assignmentPath = `/courses/${assignment.courseId}/assignments/${assignment.id}`
    const reportUrl = `${assignmentPath}/submissions/${submission.userId}/${reportType}/${entryId}`

    return (
      <SimilarityScore
        hasAdditionalData={similarityInfo.entries.length > 1}
        reportUrl={reportUrl}
        similarityScore={similarity_score}
        status={status}
      />
    )
  }

  renderProxyUploadModal = () => {
    return (
      <ProxyUploadModal
        open={this.state.proxyUploadModalOpen}
        onClose={this.closeUploadModal}
        assignment={this.props.assignment}
        student={this.props.student}
        submission={this.props.submission}
        reloadSubmission={this.props.reloadSubmission}
      />
    )
  }

  render() {
    const {name, avatarUrl} = this.props.student
    const assignmentParam = `assignment_id=${this.props.submission.assignmentId}`
    const studentParam = `student_id=${this.props.student.id}`
    const speedGraderUrlParams = this.props.assignment.anonymizeStudents
      ? assignmentParam
      : `${assignmentParam}&${studentParam}`
    const speedGraderUrl = encodeURI(
      `/courses/${this.props.courseId}/gradebook/speed_grader?${speedGraderUrlParams}`
    )

    const submissionCommentsProps = {
      submissionComments: this.props.submissionComments,
      submissionCommentsLoaded: this.props.submissionCommentsLoaded,
      deleteSubmissionComment: this.props.deleteSubmissionComment,
      createSubmissionComment: this.props.createSubmissionComment,
      processing: this.props.processing,
      setProcessing: this.props.setProcessing,
    }
    const trayIsBusy =
      this.props.processing || this.props.submissionUpdating || !this.props.submissionCommentsLoaded

    let carouselContainerStyleOverride = '0 0 0 0'

    if (!avatarUrl) {
      // When we don't have an avatar, let's ensure there's enough space between the tray close button and the student
      // carousel's previous student arrow
      carouselContainerStyleOverride = 'small 0 0 0'
    }

    let speedGraderProps = {}
    if (this.props.speedGraderEnabled) {
      speedGraderProps = {
        anonymizeStudents: this.props.assignment.anonymizeStudents,
        requireStudentGroup: this.props.requireStudentGroupForSpeedGrader,
        speedGraderUrl,
      }
    }

    return (
      <ApolloProvider client={createClient()}>
        <Tray
          contentRef={this.props.contentRef}
          label={I18n.t('Submission tray')}
          open={this.props.isOpen}
          shouldContainFocus={true}
          placement="end"
          onDismiss={this.props.onRequestClose}
          onClose={this.props.onClose}
        >
          <CloseButton
            placement="start"
            onClick={this.props.onRequestClose}
            screenReaderLabel={I18n.t('Close submission tray')}
          />
          <div className="SubmissionTray__Container">
            <div id="SubmissionTray__Content" style={{display: 'flex', flexDirection: 'column'}}>
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
                  <InstUISettingsProvider
                    theme={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
                  >
                    <Link href={this.props.student.gradesUrl} isWithinText={false}>
                      {name}
                    </Link>
                  </InstUISettingsProvider>
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
                  <InstUISettingsProvider
                    theme={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
                  >
                    <Link href={this.props.assignment.htmlUrl} isWithinText={false}>
                      {this.props.assignment.name}
                    </Link>
                  </InstUISettingsProvider>
                </Carousel>

                {this.props.speedGraderEnabled && this.renderSpeedGraderLink(speedGraderProps)}

                {this.renderSubmitForStudentLink()}

                {this.renderProxySubmissionIndicator()}

                {this.renderProxyUploadModal()}

                <View as="div" margin="small 0" className="hr" />
              </View>

              <div style={{overflowY: 'auto', flex: '1 1 auto'}}>
                {this.props.showSimilarityScore && this.renderSimilarityScore()}
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
                {!!this.props.submission.pointsDeducted && (
                  <View as="div" margin="small 0 0 0">
                    <LatePolicyGrade
                      assignment={this.props.assignment}
                      enterGradesAs={this.props.enterGradesAs}
                      gradingScheme={this.props.gradingScheme}
                      submission={this.props.submission}
                    />
                  </View>
                )}
                <View as="div" margin="small 0" className="hr" />
                <View as="div" margin="0 0 small 0" data-testid="SubmissionTray__RadioInputGroup">
                  <SubmissionTrayRadioInputGroup
                    assignment={this.props.assignment}
                    colors={this.props.colors}
                    customGradeStatuses={this.props.customGradeStatuses}
                    customGradeStatusesEnabled={this.props.customGradeStatusesEnabled}
                    disabled={this.props.gradingDisabled}
                    locale={this.props.locale}
                    latePolicy={this.props.latePolicy}
                    submission={this.props.submission}
                    submissionUpdating={this.props.submissionUpdating}
                    updateSubmission={this.props.updateSubmission}
                  />
                </View>
                <View as="div" margin="small 0" className="hr" />
                <View as="div" padding="xx-small">
                  <div id="SubmissionTray__Comments">
                    {this.renderSubmissionComments(submissionCommentsProps)}
                  </div>
                </View>
              </div>
            </div>
          </div>
        </Tray>
      </ApolloProvider>
    )
  }
}
