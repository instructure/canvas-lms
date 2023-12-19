// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState, useContext, useEffect} from 'react'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconArrowOpenDownLine,
  IconArrowOpenUpLine,
  IconAttachMediaLine,
} from '@instructure/ui-icons'
import UploadMedia from '@instructure/canvas-media'
import {formatTracksForMediaPlayer} from '@canvas/canvas-media-player'
import {Tooltip} from '@instructure/ui-tooltip'
import {Link} from '@instructure/ui-link'
import LoadingIndicator from '@canvas/loading-indicator'
import {
  UploadMediaStrings,
  MediaCaptureStrings,
  SelectStrings,
} from '@canvas/upload-media-translations'
import {Modal} from '@instructure/ui-modal'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import _ from 'lodash'
import {OBSERVER_ENROLLMENTS_QUERY} from '../graphql/Queries'
import Pill from './Pill'
import {useQuery} from 'react-apollo'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {
  FileAttachmentUpload,
  AttachmentUploadSpinner,
  AttachmentDisplay,
  MediaAttachment,
  addAttachmentsFn,
  removeAttachmentFn,
} from '@canvas/message-attachments'
import type {CamelizedAssignment} from '@canvas/grading/grading.d'

export type SendMessageArgs = {
  attachmentIds?: string[]
  recipientsIds: string[]
  subject: string
  body: string
  mediaFile?: {
    id: string
    type: string
  }
}

const I18n = useI18nScope('public_message_students_who')

export type Student = {
  id: string
  grade?: string | null
  name: string
  redoRequest?: boolean
  score?: number | null
  sortableName: string
  submittedAt: null | Date
  excused?: boolean
}

export type Props = {
  assignment?: CamelizedAssignment
  onClose: () => void
  students: Student[]
  onSend: (args: SendMessageArgs) => void
  messageAttachmentUploadFolderId: string
  userId: string
  courseId?: string
  pointsBasedGradingScheme: boolean
}

type Attachment = {
  id: string
}

type MediaTrack = {
  id: string
  src: string
  label: string
  type: string
  language: string
}

type MediaUploadFile = {
  media_id: string
  title: string
  media_type: string
  media_tracks?: MediaTrack[]
}

type FilterCriterion = {
  readonly requiresCutoff: boolean
  readonly shouldShow: (assignment: CamelizedAssignment) => boolean
  readonly title: string
  readonly value: string
}

const isScored = (assignment: CamelizedAssignment) =>
  assignment !== null &&
  ['points', 'percent', 'letter_grade', 'gpa_scale'].includes(assignment.gradingType)

const isReassignable = (assignment: CamelizedAssignment) =>
  assignment !== null &&
  (assignment.allowedAttempts === -1 || (assignment.allowedAttempts || 0) > 1) &&
  assignment.dueDate != null &&
  !assignment.submissionTypes.includes(
    'on_paper' || 'external_tool' || 'none' || 'discussion_topic' || 'online_quiz'
  )

const filterCriteria: FilterCriterion[] = [
  {
    requiresCutoff: false,
    shouldShow: assignment =>
      assignment !== null &&
      !['on_paper', 'none', 'not_graded', ''].includes(assignment.submissionTypes[0]),
    title: I18n.t('Have not yet submitted'),
    value: 'unsubmitted',
  },
  {
    requiresCutoff: false,
    shouldShow: assignment => assignment !== null,
    title: I18n.t('Have not been graded'),
    value: 'ungraded',
  },
  {
    requiresCutoff: true,
    shouldShow: isScored,
    title: I18n.t('Scored more than'),
    value: 'scored_more_than',
  },
  {
    requiresCutoff: true,
    shouldShow: isScored,
    title: I18n.t('Scored less than'),
    value: 'scored_less_than',
  },
  {
    requiresCutoff: false,
    shouldShow: assignment => assignment !== null && assignment.gradingType === 'pass_fail',
    title: I18n.t('Marked incomplete'),
    value: 'marked_incomplete',
  },
  {
    requiresCutoff: false,
    shouldShow: isReassignable,
    title: I18n.t('Reassigned'),
    value: 'reassigned',
  },
  {
    requiresCutoff: true,
    shouldShow: assignment => !assignment,
    title: I18n.t('Total grade higher than'),
    value: 'total_grade_higher_than',
  },
  {
    requiresCutoff: true,
    shouldShow: assignment => !assignment,
    title: I18n.t('Total grade lower than'),
    value: 'total_grade_lower_than',
  },
]

function observerCount(students, observers) {
  return students.reduce((acc, student) => acc + (observers[student.id]?.length || 0), 0)
}

function filterStudents(criterion, students, cutoff) {
  const newfilteredStudents: Student[] = []
  for (const student of students) {
    switch (criterion?.value) {
      case 'unsubmitted':
        if (!student.submittedAt && !student.excused) {
          newfilteredStudents.push(student)
        }
        break
      case 'ungraded':
        if (!student.grade && !student.excused) {
          newfilteredStudents.push(student)
        }
        break
      case 'scored_more_than':
        if (parseFloat(student.score) > cutoff) {
          newfilteredStudents.push(student)
        }
        break
      case 'scored_less_than':
        if (parseFloat(student.score) < cutoff) {
          newfilteredStudents.push(student)
        }
        break
      case 'marked_incomplete':
        if (student.grade === 'incomplete') {
          newfilteredStudents.push(student)
        }
        break
      case 'reassigned':
        if (student.redoRequest) {
          newfilteredStudents.push(student)
        }
        break
      case 'total_grade_higher_than':
        if (parseFloat(student.currentScore) > cutoff) {
          newfilteredStudents.push(student)
        }
        break
      case 'total_grade_lower_than':
        if (parseFloat(student.currentScore) < cutoff) {
          newfilteredStudents.push(student)
        }
        break
    }
  }
  return newfilteredStudents
}

function defaultSubject(criterion, assignment, cutoff, pointsBasedGradingScheme) {
  if (cutoff === '') {
    cutoff = 0
  }

  if (assignment !== null) {
    switch (criterion) {
      case 'unsubmitted':
        return I18n.t('No submission for %{assignment}', {assignment: assignment.name})
      case 'ungraded':
        return I18n.t('No grade for %{assignment}', {assignment: assignment.name})
      case 'scored_more_than':
        return I18n.t('Scored more than %{cutoff} on %{assignment}', {
          cutoff,
          assignment: assignment.name,
        })
      case 'scored_less_than':
        return I18n.t('Scored less than %{cutoff} on %{assignment}', {
          cutoff,
          assignment: assignment.name,
        })
      case 'marked_incomplete':
        return I18n.t('%{assignment} is incomplete', {assignment: assignment.name})
      case 'reassigned':
        return I18n.t('%{assignment} is reassigned', {assignment: assignment.name})
    }
  } else {
    switch (criterion) {
      case 'total_grade_higher_than':
        return pointsBasedGradingScheme
          ? I18n.t('Current total score is higher than %{cutoff}', {
              cutoff,
            })
          : I18n.t('Current total score is higher than %{cutoff}%', {
              cutoff,
            })
      case 'total_grade_lower_than':
        return pointsBasedGradingScheme
          ? I18n.t('Current total score is lower than %{cutoff}', {
              cutoff,
            })
          : I18n.t('Current total score is lower than %{cutoff}%', {
              cutoff,
            })
    }
  }
}

const MessageStudentsWhoDialog = ({
  assignment,
  onClose,
  students,
  onSend,
  messageAttachmentUploadFolderId,
  userId,
  courseId,
  pointsBasedGradingScheme = true,
}: Props) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [open, setOpen] = useState(true)
  const [sending, setSending] = useState(false)
  const [message, setMessage] = useState('')

  const initializeSelectedObservers = studentCollection =>
    studentCollection.reduce((map, student) => {
      map[student.id] = []
      return map
    }, {})

  const [selectedObservers, setSelectedObservers] = useState(initializeSelectedObservers(students))
  const [selectedStudents, setSelectedStudents] = useState(Object.keys(selectedObservers))
  const [isIndeterminateStudentsCheckbox, setIsIndeterminateStudentsCheckbox] = useState(false)
  const [isIndeterminateObserversCheckbox, setIsIndeterminateObserversCheckbox] = useState(false)
  const [isCheckedStudentsCheckbox, setIsCheckedStudentsCheckbox] = useState(true)
  const [isCheckedObserversCheckbox, setIsCheckedObserversCheckbox] = useState(false)
  const [isDisabledStudentsCheckbox, setIsDisabledStudentsCheckbox] = useState(false)
  const [isDisabledObserversCheckbox, setIsDisabledObserversCheckbox] = useState(false)
  const [mediaUploadOpen, setMediaUploadOpen] = useState<boolean>(false)
  const [mediaUploadFile, setMediaUploadFile] = useState<null | MediaUploadFile>(null)
  const [mediaPreviewURL, setMediaPreviewURL] = useState<null | string>(null)
  const [mediaTitle, setMediaTitle] = useState<string>('')
  const close = () => setOpen(false)

  const {loading, data} = useQuery(OBSERVER_ENROLLMENTS_QUERY, {
    variables: {
      courseId: assignment?.courseId || courseId,
      studentIds: students.map(student => student.id),
    },
  })

  const observerEnrollments = data?.course?.enrollmentsConnection?.nodes || []
  const observersByStudentID = observerEnrollments.reduce((results, enrollment) => {
    const observeeId = enrollment.associatedUser._id
    results[observeeId] = results[observeeId] || []
    const existingObservers = results[observeeId]

    if (!existingObservers.some(user => user._id === enrollment.user._id)) {
      results[observeeId].push(enrollment.user)
    }

    return results
  }, {})

  const isLengthBetweenBoundaries = (subsetLength: number, totalLength: number) =>
    subsetLength > 0 && subsetLength < totalLength

  const [cutoff, setCutoff] = useState(0.0)
  const availableCriteria = filterCriteria.filter(criterion => criterion.shouldShow(assignment))
  const sortedStudents = [...students].sort((a, b) => a.sortableName.localeCompare(b.sortableName))
  const [filteredStudents, setFilteredStudents] = useState(
    filterStudents(availableCriteria[0], sortedStudents, cutoff)
  )
  const [subject, setSubject] = useState(
    defaultSubject(availableCriteria[0].value, assignment, cutoff, pointsBasedGradingScheme)
  )
  const [observersDisplayed, setObserversDisplayed] = useState(0.0)

  useEffect(() => {
    const partialStudentSelection = isLengthBetweenBoundaries(
      selectedStudents.length,
      filteredStudents.length
    )
    setIsIndeterminateStudentsCheckbox(partialStudentSelection)
    setIsDisabledStudentsCheckbox(filteredStudents.length === 0)
    setIsCheckedStudentsCheckbox(
      filteredStudents.length > 0 && selectedStudents.length === filteredStudents.length
    )
  }, [selectedStudents, filteredStudents])

  useEffect(() => {
    const observerCountValue = observerCount(filteredStudents, observersByStudentID)
    const selectedObserverCount = Object.values(selectedObservers).reduce(
      (acc: number, array: any) => acc + array.length,
      0
    )
    const partialObserverSelection = isLengthBetweenBoundaries(
      selectedObserverCount,
      observerCountValue
    )
    setIsIndeterminateObserversCheckbox(partialObserverSelection)
    setIsDisabledObserversCheckbox(observerCountValue === 0)
    setIsCheckedObserversCheckbox(
      observerCountValue > 0 && selectedObserverCount === observerCountValue
    )
  }, [filteredStudents, observersByStudentID, selectedObservers])

  useEffect(() => {
    const initialValue = initializeSelectedObservers(filteredStudents)
    setSelectedObservers(initialValue)
    setSelectedStudents(Object.keys(initialValue))
  }, [filteredStudents])

  const [showTable, setShowTable] = useState(false)
  const [selectedCriterion, setSelectedCriterion] = useState(availableCriteria[0])
  const [attachments, setAttachments] = useState<Attachment[]>([])
  const [pendingUploads, setPendingUploads] = useState([])

  const isFormDataValid: boolean =
    message.trim().length > 0 &&
    selectedStudents.length + Object.values(selectedObservers).flat().length > 0

  useEffect(() => {
    if (!loading && data) {
      setObserversDisplayed(
        observerCount(
          filterStudents(selectedCriterion, sortedStudents, cutoff),
          observersByStudentID
        )
      )
    }
  }, [loading, data, selectedCriterion, sortedStudents, cutoff, observersByStudentID])

  useEffect(() => {
    return () => {
      if (mediaPreviewURL) {
        URL.revokeObjectURL(mediaPreviewURL)
      }
    }
  }, [mediaPreviewURL])

  if (loading) {
    return <LoadingIndicator />
  }

  const handleCriterionSelected = (_e, {value}) => {
    const newCriterion = filterCriteria.find(criterion => criterion.value === value)
    if (newCriterion != null) {
      setSelectedCriterion(newCriterion)
      setFilteredStudents(filterStudents(newCriterion, sortedStudents, cutoff))
      setObserversDisplayed(
        observerCount(filterStudents(newCriterion, sortedStudents, cutoff), observersByStudentID)
      )
      setSubject(defaultSubject(newCriterion.value, assignment, cutoff, pointsBasedGradingScheme))
    }
  }

  const handleSendButton = () => {
    if (pendingUploads.length) {
      // This notifies the AttachmentUploadSpinner to start spinning
      // which then calls onSend() when pendingUploads are complete.
      setSending(true)
    } else {
      const recipientsIds = [
        ...selectedStudents,
        ...Object.values(selectedObservers).flat(),
      ] as string[]
      const uniqueRecipientsIds: string[] = [...new Set(recipientsIds)]

      const args: SendMessageArgs = {
        recipientsIds: uniqueRecipientsIds,
        subject,
        body: message,
      }

      if (mediaUploadFile) {
        args.mediaFile = {
          id: mediaUploadFile.media_id,
          type: mediaUploadFile.media_type,
        }
      }

      if (attachments?.length) {
        args.attachmentIds = attachments.map((attachment: Attachment) => attachment.id)
      }

      onSend(args)
      onClose()
    }
  }

  const onAddAttachment = addAttachmentsFn(
    setAttachments,
    setPendingUploads,
    messageAttachmentUploadFolderId,
    setOnFailure,
    setOnSuccess
  )
  const onDeleteAttachment = removeAttachmentFn(setAttachments)
  const onReplaceAttachment = (id, e) => {
    onDeleteAttachment(id)
    onAddAttachment(e)
  }
  const onRemoveMediaComment = () => {
    if (mediaPreviewURL) {
      URL.revokeObjectURL(mediaPreviewURL)
      setMediaPreviewURL(null)
    }
    setMediaUploadFile(null)
  }

  const onMediaUploadStart = file => {
    setMediaTitle(file.title)
  }

  const onMediaUploadComplete = (err, mediaData, captionData) => {
    if (err) {
      setOnFailure(I18n.t('There was an error uploading the media.'))
    } else {
      const file = mediaData.mediaObject.media_object
      if (captionData && file) {
        file.media_tracks = formatTracksForMediaPlayer(captionData)
      }
      setMediaUploadFile(file)
      setMediaPreviewURL(URL.createObjectURL(mediaData.uploadedFile))
    }
  }

  const toggleSelection = (id: string, array: Array<string>) => {
    const index = array.indexOf(id)
    const newArray = [...array]
    if (index === -1) {
      newArray.push(id)
    } else {
      newArray.splice(index, 1)
    }
    return newArray
  }

  const toggleStudentSelection = (id: string) => {
    setSelectedStudents(toggleSelection(id, selectedStudents))
  }

  const toggleObserverSelection = (studentId: string, observerId: string) => {
    const observers = selectedObservers[studentId]
    const updatedObservers = toggleSelection(observerId, observers)
    setSelectedObservers({...selectedObservers, [studentId]: updatedObservers})
  }

  const onStudentsCheckboxChanged = event => {
    if (event.target.checked) {
      setSelectedStudents(filteredStudents.map(element => element.id))
    } else {
      setSelectedStudents([])
    }
  }

  const onObserversCheckboxChanged = event => {
    if (event.target.checked) {
      setSelectedObservers(
        filteredStudents.reduce((map, student) => {
          const observers = observersByStudentID[student.id] || []
          map[student.id] = Object.keys(observers).map(key => observers[key]._id)
          return map
        }, {})
      )
    } else {
      setSelectedObservers(initializeSelectedObservers(students))
    }
  }

  return (
    <>
      <Modal
        open={open}
        label={I18n.t('Compose Message')}
        onDismiss={close}
        onExited={onClose}
        overflow="scroll"
        shouldCloseOnDocumentClick={false}
        size="large"
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={close}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Compose Message')}</Heading>
        </Modal.Header>

        <Modal.Body>
          <Flex alignItems="end">
            <Flex.Item>
              <SimpleSelect
                renderLabel={I18n.t('For students who…')}
                onChange={handleCriterionSelected}
                value={selectedCriterion.value}
              >
                {availableCriteria.map(criterion => (
                  <SimpleSelect.Option
                    id={`criteria_${criterion.value}`}
                    key={criterion.value}
                    value={criterion.value}
                  >
                    {criterion.title}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect>
            </Flex.Item>
            {selectedCriterion.requiresCutoff && (
              <Flex.Item margin="0 0 0 small">
                <NumberInput
                  value={cutoff}
                  onChange={(_e, value) => {
                    setCutoff(value)
                    if (value !== '') {
                      setFilteredStudents(filterStudents(selectedCriterion, sortedStudents, value))
                      setSubject(
                        defaultSubject(
                          selectedCriterion.value,
                          assignment,
                          value,
                          pointsBasedGradingScheme
                        )
                      )
                    }
                  }}
                  showArrows={false}
                  renderLabel={
                    <ScreenReaderContent>{I18n.t('Enter score cutoff')}</ScreenReaderContent>
                  }
                  width="5em"
                />
              </Flex.Item>
            )}
          </Flex>
          <br />
          <Flex>
            <Flex.Item>
              <Text weight="bold">{I18n.t('Send Message To:')}</Text>
            </Flex.Item>
            <Flex.Item margin="0 0 0 medium">
              <Checkbox
                indeterminate={isIndeterminateStudentsCheckbox}
                disabled={isDisabledStudentsCheckbox}
                onChange={onStudentsCheckboxChanged}
                checked={isCheckedStudentsCheckbox}
                defaultChecked={true}
                label={
                  <Text weight="bold">
                    {I18n.t('%{studentCount} Students', {studentCount: filteredStudents.length})}
                  </Text>
                }
              />
            </Flex.Item>
            <Flex.Item margin="0 0 0 medium">
              <Checkbox
                indeterminate={isIndeterminateObserversCheckbox}
                disabled={isDisabledObserversCheckbox}
                onChange={onObserversCheckboxChanged}
                checked={isCheckedObserversCheckbox}
                label={
                  <Text weight="bold">
                    {I18n.t('%{observerCount} Observers', {
                      observerCount: observersDisplayed,
                    })}
                  </Text>
                }
              />
            </Flex.Item>
            <Flex.Item as="div" shouldGrow={true} textAlign="end">
              <Link
                onClick={() => setShowTable(!showTable)}
                renderIcon={showTable ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
                iconPlacement="end"
                data-testid="show_all_recipients"
              >
                {showTable ? I18n.t('Hide all recipients') : I18n.t('Show all recipients')}
              </Link>
            </Flex.Item>
          </Flex>
          {showTable && (
            <Table caption={I18n.t('List of students and observers')}>
              <Table.Head>
                <Table.Row>
                  <Table.ColHeader id="students">{I18n.t('Students')}</Table.ColHeader>
                  <Table.ColHeader id="observers">{I18n.t('Observers')}</Table.ColHeader>
                </Table.Row>
              </Table.Head>
              <Table.Body>
                {filteredStudents.map(student => (
                  <Table.Row key={student.id}>
                    <Table.Cell>
                      <Pill
                        studentId={student.id}
                        text={student.name}
                        selected={selectedStudents.includes(student.id)}
                        onClick={toggleStudentSelection}
                      />
                    </Table.Cell>
                    <Table.Cell>
                      <Flex direction="row" margin="0 0 0 small" wrap="wrap">
                        {_.sortBy(
                          observersByStudentID[student.id] || [],
                          observer => observer.sortableName
                        ).map(observer => (
                          <Flex.Item key={observer._id}>
                            <Pill
                              studentId={student.id}
                              observerId={observer._id}
                              text={observer.name}
                              selected={selectedObservers[student.id]?.includes(observer._id)}
                              onClick={toggleObserverSelection}
                            />
                          </Flex.Item>
                        ))}
                      </Flex>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table.Body>
            </Table>
          )}

          <br />
          <TextInput
            data-testid="subject-input"
            renderLabel={I18n.t('Subject')}
            placeholder={I18n.t('Type Something…')}
            value={subject}
            onChange={(_event, value) => {
              setSubject(value)
            }}
          />
          <br />
          <TextArea
            data-testid="message-input"
            required={true}
            height="200px"
            label={I18n.t('Message')}
            placeholder={I18n.t('Type your message here…')}
            value={message}
            onChange={e => setMessage(e.target.value)}
          />

          <Flex alignItems="start">
            {mediaUploadFile && mediaPreviewURL && (
              <Flex.Item>
                <MediaAttachment
                  file={{
                    mediaID: mediaUploadFile.media_id,
                    src: mediaPreviewURL,
                    title: mediaTitle || mediaUploadFile.title,
                    type: mediaUploadFile.media_type,
                    mediaTracks: mediaUploadFile.media_tracks,
                  }}
                  onRemoveMediaComment={onRemoveMediaComment}
                />
              </Flex.Item>
            )}

            <Flex.Item shouldShrink={true}>
              <AttachmentDisplay
                attachments={[...attachments, ...pendingUploads]}
                onDeleteItem={onDeleteAttachment}
                onReplaceItem={onReplaceAttachment}
              />
            </Flex.Item>
          </Flex>
        </Modal.Body>

        <Modal.Footer>
          <Flex justifyItems="space-between" width="100%">
            <Flex.Item>
              <FileAttachmentUpload onAddItem={onAddAttachment} />

              <Tooltip renderTip={I18n.t('Record an audio or video comment')} placement="top">
                <IconButton
                  screenReaderLabel={I18n.t('Record an audio or video comment')}
                  onClick={() => setMediaUploadOpen(true)}
                  margin="xx-small"
                  data-testid="media-upload"
                  interaction={mediaUploadFile ? 'disabled' : 'enabled'}
                >
                  <IconAttachMediaLine />
                </IconButton>
              </Tooltip>
            </Flex.Item>

            <Flex.Item>
              <Flex>
                <Flex.Item>
                  <Button focusColor="info" color="primary-inverse" onClick={close}>
                    {I18n.t('Cancel')}
                  </Button>
                </Flex.Item>
                <Flex.Item margin="0 0 0 x-small">
                  <Button
                    data-testid="send-message-button"
                    interaction={isFormDataValid ? 'enabled' : 'disabled'}
                    color="primary"
                    onClick={handleSendButton}
                  >
                    {I18n.t('Send')}
                  </Button>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Modal.Footer>
      </Modal>
      <AttachmentUploadSpinner
        sendMessage={onSend}
        isMessageSending={sending}
        pendingUploads={pendingUploads}
      />
      <UploadMedia
        key={mediaUploadFile?.media_id}
        onStartUpload={onMediaUploadStart}
        onUploadComplete={onMediaUploadComplete}
        onDismiss={() => setMediaUploadOpen(false)}
        open={mediaUploadOpen}
        tabs={{embed: false, record: true, upload: true}}
        uploadMediaTranslations={{UploadMediaStrings, MediaCaptureStrings, SelectStrings}}
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
        rcsConfig={{contextId: userId, contextType: 'user'}}
        disableSubmitWhileUploading={true}
        userLocale={ENV.LOCALE}
      />
    </>
  )
}

export default MessageStudentsWhoDialog
