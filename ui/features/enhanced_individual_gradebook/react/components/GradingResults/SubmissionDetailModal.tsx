/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {IconAudioSolid, IconUserSolid} from '@instructure/ui-icons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Link} from '@instructure/ui-link'
import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'
import {useSubmitScore} from '../../hooks/useSubmitScore'
import {
  ApiCallStatus,
  type AssignmentConnection,
  type Attachment,
  type CommentConnection,
  type GradebookOptions,
  type GradebookStudentDetails,
  type GradebookUserSubmissionDetails,
} from '../../../types'
import {
  submitterPreviewText,
  disableGrading,
  passFailStatusOptions,
} from '../../../utils/gradebookUtils'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {usePostComment} from '../../hooks/useComments'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import DefaultGradeInput from './DefaultGradeInput'

const I18n = useI18nScope('enhanced_individual_gradebook')

export type GradeChangeApiUpdate = {
  status: ApiCallStatus
  newSubmission?: GradebookUserSubmissionDetails | null
  error: string
}

type Props = {
  assignment: AssignmentConnection
  gradebookOptions: GradebookOptions
  student: GradebookStudentDetails
  submission: GradebookUserSubmissionDetails
  comments: CommentConnection[]
  modalOpen: boolean
  loadingComments: boolean
  submitScoreUrl: string
  onGradeChange: (updateEvent: GradeChangeApiUpdate) => void
  onPostComment: () => void
  handleClose: () => void
}

export default function SubmissionDetailModal({
  assignment,
  gradebookOptions,
  student,
  submission,
  comments,
  loadingComments,
  modalOpen,
  submitScoreUrl,
  handleClose,
  onGradeChange,
  onPostComment,
}: Props) {
  const speedGraderUrl = () => {
    return `${gradebookOptions.contextUrl}/gradebook/speed_grader?assignment_id=${assignment.id}`
  }

  return (
    <Modal
      open={modalOpen}
      onDismiss={() => {}}
      size="medium"
      label="Student Submission Detail Modal"
      shouldCloseOnDocumentClick={false}
      themeOverride={{mediumMaxWidth: '40em'}}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={() => handleClose()}
          screenReaderLabel="Close Submission Detail"
        />
        <Heading level="h4">{student.name}</Heading>
      </Modal.Header>
      <Modal.Body padding="none">
        <View
          as="div"
          padding="medium medium 0 medium"
          data-testid="submission-details-assignment-name"
        >
          <Heading level="h3">{assignment?.name}</Heading>
        </View>

        <SubmissionGradeForm
          assignment={assignment}
          submission={submission}
          submitScoreUrl={submitScoreUrl}
          onGradeChange={onGradeChange}
        />

        <View as="div" margin="small 0" padding="0 medium">
          <Link href={speedGraderUrl()} isWithinText={false}>
            {I18n.t('More details in the SpeedGrader')}
          </Link>
        </View>

        <View as="div" margin="small 0" padding="0 medium">
          <View as="b">{submitterPreviewText(submission)}</View>
        </View>

        {loadingComments && <LoadingIndicator />}

        {!loadingComments && comments.length > 0 && (
          <View as="div" margin="small 0">
            <Heading level="h3" margin="0 medium">
              {I18n.t('Comments')}
            </Heading>

            <View as="div" margin="small 0" maxHeight="9rem" overflowX="auto">
              {comments.map((comment, index) => (
                <SubmissionComment
                  key={comment.id}
                  comment={comment}
                  showDivider={index < comments.length - 1}
                />
              ))}
            </View>
          </View>
        )}

        <PostCommentForm
          assignment={assignment}
          submitScoreUrl={submitScoreUrl}
          onPostComment={onPostComment}
        />
      </Modal.Body>
    </Modal>
  )
}

type SubmissionCommentProps = {
  comment: CommentConnection
  showDivider: boolean
}
function SubmissionComment({comment, showDivider}: SubmissionCommentProps) {
  const {attachments, author, mediaObject} = comment
  return (
    <View
      as="div"
      key={comment.id}
      padding="0 medium"
      elementRef={current => {
        if (current) {
          current.scrollIntoView()
        }
      }}
    >
      <Flex alignItems="start">
        <Link href={author.htmlUrl} isWithinText={false}>
          <SubmissionCommentAvatar comment={comment} />
        </Link>
        <Flex.Item shouldGrow={true} shouldShrink={true} padding="0 0 0 small">
          <Heading level="h5">
            <Link href={author.htmlUrl} isWithinText={false}>
              {author.name}
            </Link>
          </Heading>
          <Text size="small">{comment.comment}</Text>
          {mediaObject && (
            <View as="div">
              <Link
                href={mediaObject.mediaDownloadUrl}
                renderIcon={IconAudioSolid}
                isWithinText={false}
              >
                {I18n.t('click here to view')}
              </Link>
            </View>
          )}

          {attachments.length > 0 &&
            attachments.map(attachment => (
              <CommentAttachment key={attachment.id} attachment={attachment} />
            ))}
        </Flex.Item>
        <Flex.Item align="start">
          <Heading level="h5">
            <FriendlyDatetime dateTime={comment.updatedAt} />
          </Heading>
        </Flex.Item>
      </Flex>

      {showDivider && <hr key="hrcomment-{comment.id}" style={{margin: '.6rem 0'}} />}
    </View>
  )
}

type CommentAttachmentProps = {
  attachment: Attachment
}
function CommentAttachment({attachment}: CommentAttachmentProps) {
  return (
    <View as="div" key={attachment.id}>
      <Link
        href={attachment.url}
        isWithinText={false}
        renderIcon={getIconByType(attachment.mimeClass)}
      >
        <Text size="x-small">{attachment.displayName}</Text>
      </Link>
    </View>
  )
}

function SubmissionCommentAvatar({comment}: {comment: CommentConnection}) {
  if (comment.author.avatarUrl) {
    return <Avatar name={comment.author.name} src={comment.author.avatarUrl} />
  }

  return <Avatar name="user" renderIcon={<IconUserSolid />} color="ash" />
}

type SubmissionGradeFormProps = {
  assignment: AssignmentConnection
  submission: GradebookUserSubmissionDetails
  submitScoreUrl?: string | null
  onGradeChange: (updateEvent: GradeChangeApiUpdate) => void
}
function SubmissionGradeForm({
  assignment,
  submission,
  submitScoreUrl,
  onGradeChange,
}: SubmissionGradeFormProps) {
  const [gradeInput, setGradeInput] = useState<string>('')
  const [passFailStatusIndex, setPassFailStatusIndex] = useState<number>(0)
  const {submit, submitScoreError, submitScoreStatus, savedSubmission} = useSubmitScore()

  useEffect(() => {
    onGradeChange({
      status: submitScoreStatus,
      newSubmission: savedSubmission,
      error: submitScoreError,
    })
  }, [submitScoreStatus, savedSubmission, submitScoreError, onGradeChange])

  useEffect(() => {
    if (submission) {
      if (assignment?.gradingType === 'pass_fail') {
        const index = passFailStatusOptions.findIndex(
          passFailStatusOption =>
            passFailStatusOption.value === submission.grade ||
            (passFailStatusOption.value === 'EX' && submission.excused)
        )
        if (index !== -1) {
          setPassFailStatusIndex(index)
        } else {
          setPassFailStatusIndex(0)
        }
      }

      if (submission.excused) {
        setGradeInput(I18n.t('EX'))
      } else if (submission.grade == null) {
        setGradeInput('-')
      } else if (assignment?.gradingType === 'letter_grade') {
        setGradeInput(GradeFormatHelper.replaceDashWithMinus(submission.grade))
      } else {
        setGradeInput(submission.grade)
      }
    }
  }, [assignment, submission])

  const submitGrade = async () => {
    await submit(assignment, submission, gradeInput, submitScoreUrl)
  }

  const handleChangePassFailStatus = (
    event: React.SyntheticEvent,
    data: {value?: string | number}
  ) => {
    if (typeof data.value === 'string') {
      setGradeInput(data.value)
      setPassFailStatusIndex(passFailStatusOptions.findIndex(option => option.value === data.value))
    }
  }

  return (
    <View as="div" margin="small 0" padding="0 medium">
      <Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text>{I18n.t('Grade:')} </Text>
          <DefaultGradeInput
            assignment={assignment}
            submission={submission}
            passFailStatusIndex={passFailStatusIndex}
            gradeInput={gradeInput}
            submitScoreStatus={submitScoreStatus}
            context="submission_details_grade"
            elementWrapper="span"
            margin="0 x-small 0 x-small"
            handleSetGradeInput={setGradeInput}
            handleChangePassFailStatus={handleChangePassFailStatus}
          />
        </Flex.Item>
        <Flex.Item align="start">
          <Button
            data-testid="submission-details-submit-button"
            disabled={disableGrading(assignment, submitScoreStatus)}
            onClick={() => submitGrade()}
          >
            {I18n.t('Update Grade')}
          </Button>
        </Flex.Item>
      </Flex.Item>
    </View>
  )
}

type PostCommentFormProps = {
  assignment: AssignmentConnection
  submitScoreUrl?: string | null
  onPostComment: () => void
}
function PostCommentForm({assignment, submitScoreUrl, onPostComment}: PostCommentFormProps) {
  const {groupCategoryId, gradeGroupStudentsIndividually} = assignment
  const [newComment, setNewComment] = useState<string>('')
  const [isGroupComment, setIsGroupComment] = useState<boolean>(false)
  const {postCommentError, postCommentStatus, submit} = usePostComment()

  const submitComment = async () => {
    let shouldSendGroupComment: boolean | undefined

    if (groupCategoryId) {
      shouldSendGroupComment = gradeGroupStudentsIndividually ? isGroupComment : true
    }

    await submit(newComment, shouldSendGroupComment, submitScoreUrl)
  }

  const groupRadioInputs = [
    {value: '0', label: 'Send comment to this student only'},
    {value: '1', label: 'Send comment to the whole group'},
  ]

  const handleGroupCommentChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setIsGroupComment(event.target.value === '1')
  }

  useEffect(() => {
    switch (postCommentStatus) {
      case ApiCallStatus.COMPLETED:
        setNewComment('')
        onPostComment()
        break
      case ApiCallStatus.FAILED:
        showFlashError(postCommentError)(new Error('Failed to add comment'))
        break
    }
  }, [postCommentStatus, postCommentError, onPostComment])

  return (
    <div style={{backgroundColor: '#F2F2F2', borderTop: '1px solid #bbb'}}>
      <View as="div" padding="small medium">
        <TextArea
          label={I18n.t('Add a comment')}
          maxHeight="4rem"
          value={newComment}
          onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setNewComment(e.target.value)}
        />
        <Flex.Item margin="small 0 0 0">
          <Flex.Item padding="x-small" shouldShrink={true} shouldGrow={true}>
            {groupCategoryId && (
              <div>
                {gradeGroupStudentsIndividually ? (
                  <RadioInputGroup
                    onChange={handleGroupCommentChange}
                    defaultValue="0"
                    name="groupComment"
                    description={
                      <ScreenReaderContent>{I18n.t('Send to all of group')}</ScreenReaderContent>
                    }
                  >
                    {groupRadioInputs.map(input => (
                      <RadioInput key={input.value} value={input.value} label={input.label} />
                    ))}
                  </RadioInputGroup>
                ) : (
                  <Text size="small">{I18n.t('All comments are sent to the whole group')}</Text>
                )}
              </div>
            )}
          </Flex.Item>
          <Flex.Item align="start">
            <Button disabled={postCommentStatus === ApiCallStatus.PENDING} onClick={submitComment}>
              {I18n.t('Post Comment')}
            </Button>
          </Flex.Item>
        </Flex.Item>
      </View>
    </div>
  )
}
