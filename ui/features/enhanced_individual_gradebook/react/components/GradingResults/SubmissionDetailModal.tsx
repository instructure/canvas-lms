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
// @ts-expect-error
import {IconAudioSolid, IconUserSolid} from '@instructure/ui-icons'
import {Heading} from '@instructure/ui-heading'
// @ts-expect-error
import {Modal} from '@instructure/ui-modal'
// @ts-expect-error
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
// @ts-expect-error
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Link} from '@instructure/ui-link'
import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'
import {useSubmitScore} from '../../hooks/useSubmitScore'
import {
  ApiCallStatus,
  AssignmentConnection,
  Attachment,
  CommentConnection,
  GradebookOptions,
  GradebookStudentDetails,
  GradebookUserSubmissionDetails,
} from '../../../types'
import {submitterPreviewText, outOfText} from '../../../utils/gradebookUtils'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {usePostComment} from '../../hooks/useComments'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('enhanced_individual_gradebook')

const {Header: ModalHeader, Body: ModalBody} = Modal as any

const {Item: FlexItem} = Flex as any

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
      theme={{mediumMaxWidth: '40em'}}
    >
      <ModalHeader>
        <CloseButton
          placement="end"
          offset="small"
          onClick={() => handleClose()}
          screenReaderLabel="Close Submission Detail"
        />
        <Heading level="h4">{student.name}</Heading>
      </ModalHeader>
      <ModalBody padding="none">
        <View as="div" padding="medium medium 0 medium">
          <Heading level="h3">{assignment?.name}</Heading>
        </View>

        <SubmissionGradeForm
          assignment={assignment}
          submission={submission}
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
          submission={submission}
          onPostComment={onPostComment}
        />
      </ModalBody>
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
        <FlexItem shouldGrow={true} shouldShrink={true} padding="0 0 0 small">
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
            attachments.map(attachment => <CommentAttachment attachment={attachment} />)}
        </FlexItem>
        <FlexItem align="start">
          <Heading level="h5">
            <FriendlyDatetime dateTime={comment.updatedAt} />
          </Heading>
        </FlexItem>
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
  onGradeChange: (updateEvent: GradeChangeApiUpdate) => void
}
function SubmissionGradeForm({assignment, submission, onGradeChange}: SubmissionGradeFormProps) {
  const [gradeInput, setGradeInput] = useState<string>('')
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
      setGradeInput(submission?.grade ?? '-')
    }
  }, [submission])

  const submitGrade = async () => {
    await submit(assignment, submission, gradeInput)
  }

  return (
    <View as="div" margin="small 0" padding="0 medium">
      <Flex>
        <FlexItem shouldGrow={true} shouldShrink={true}>
          <Text>{I18n.t('Grade:')} </Text>
          <View as="span" margin="0 x-small 0 x-small">
            <TextInput
              renderLabel={<ScreenReaderContent>{I18n.t('Student Grade')}</ScreenReaderContent>}
              display="inline-block"
              width="4rem"
              value={gradeInput}
              disabled={submitScoreStatus === ApiCallStatus.PENDING}
              onChange={e => setGradeInput(e.target.value)}
            />
          </View>
          <Text>{outOfText(assignment, submission)}</Text>
        </FlexItem>
        <FlexItem align="start">
          <Button
            disabled={submitScoreStatus === ApiCallStatus.PENDING}
            onClick={() => submitGrade()}
          >
            {I18n.t('Update Grade')}
          </Button>
        </FlexItem>
      </Flex>
    </View>
  )
}

type PostCommentFormProps = {
  submission: GradebookUserSubmissionDetails
  assignment: AssignmentConnection
  onPostComment: () => void
}
function PostCommentForm({submission, assignment, onPostComment}: PostCommentFormProps) {
  const {groupCategoryId, gradeGroupStudentsIndividually} = assignment
  const [newComment, setNewComment] = useState<string>('')
  const [isGroupComment, setIsGroupComment] = useState<boolean>(false)
  const {postCommentError, postCommentStatus, submit} = usePostComment()

  const submitComment = async () => {
    let shouldSendGroupComment: boolean | undefined

    if (groupCategoryId) {
      shouldSendGroupComment = gradeGroupStudentsIndividually ? isGroupComment : true
    }

    await submit(assignment, submission, newComment, shouldSendGroupComment)
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
        <Flex margin="small 0 0 0">
          <FlexItem padding="x-small" shouldShrink={true} shouldGrow={true}>
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
          </FlexItem>
          <FlexItem align="start">
            <Button disabled={postCommentStatus === ApiCallStatus.PENDING} onClick={submitComment}>
              {I18n.t('Post Comment')}
            </Button>
          </FlexItem>
        </Flex>
      </View>
    </div>
  )
}
