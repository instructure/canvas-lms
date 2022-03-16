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

import React, {useState, useContext} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconAddSolid,
  IconArrowOpenDownLine,
  IconArrowOpenUpLine,
  IconXSolid
} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import LoadingIndicator from '@canvas/loading-indicator'
import {Modal} from '@instructure/ui-modal'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Table} from '@instructure/ui-table'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'

import _ from 'lodash'
import {OBSERVER_ENROLLMENTS_QUERY} from '../graphql/Queries'

import {useQuery} from 'react-apollo'

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {
  FileAttachmentUpload,
  AttachmentUploadSpinner,
  AttachmentDisplay,
  addAttachmentsFn,
  removeAttachmentFn
} from '@canvas/message-attachments'

const I18n = useI18nScope('public_message_students_who')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item} = Flex as any
const {Header: ModalHeader, Body: ModalBody, Footer: ModalFooter} = Modal as any
const {Option} = SimpleSelect as any
const {Body: TableBody, Cell, ColHeader, Head: TableHead, Row} = Table as any

export type Student = {
  id: string
  name: string
  sortableName: string
}

export type Assignment = {
  courseId: string
  gradingType: string
  id: string
  name: string
  nonDigitalSubmission: boolean
}

export type Props = {
  assignment: Assignment
  onClose: () => void
  students: Student[]
  onSend: () => void
  messageAttachmentUploadFolderId: string
}

type FilterCriterion = {
  readonly requiresCutoff: boolean
  readonly shouldShow: (assignment: Assignment) => boolean
  readonly title: string
  readonly value: string
}

const isScored = (assignment: Assignment) =>
  ['points', 'percent', 'letter_grade', 'gpa_scale'].includes(assignment.gradingType)

const filterCriteria: FilterCriterion[] = [
  {
    requiresCutoff: false,
    shouldShow: assignment => !assignment.nonDigitalSubmission,
    title: I18n.t('Have not yet submitted'),
    value: 'unsubmitted'
  },
  {
    requiresCutoff: false,
    shouldShow: () => true,
    title: I18n.t('Have not been graded'),
    value: 'ungraded'
  },
  {
    requiresCutoff: true,
    shouldShow: isScored,
    title: I18n.t('Scored more than'),
    value: 'scored_more_than'
  },
  {
    requiresCutoff: true,
    shouldShow: isScored,
    title: I18n.t('Scored less than'),
    value: 'scored_less_than'
  },
  {
    requiresCutoff: false,
    shouldShow: assignment => assignment.gradingType === 'pass_fail',
    title: I18n.t('Marked incomplete'),
    value: 'marked_incomplete'
  },
  {
    requiresCutoff: false,
    shouldShow: () => true,
    title: I18n.t('Reassigned'),
    value: 'reassigned'
  }
]

// Interim Tag-like component representing a selectable student or observer
// until whatever we're using gets finalized
// Still needed: some sort of onClick handler so we can select and deselect
const FakeTag = ({text, selected = false}) => {
  const contents = selected ? (
    <>
      <View margin="0 small 0 0">
        <Text color="primary">{text}</Text>
      </View>
      <IconXSolid />
    </>
  ) : (
    <>
      <View margin="0 small 0 0">
        <Text color="secondary">{text}</Text>
      </View>
      <IconAddSolid color="brand" />
    </>
  )

  return <Tag text={contents} />
}

const MessageStudentsWhoDialog: React.FC<Props> = ({
  assignment,
  onClose,
  students,
  onSend,
  messageAttachmentUploadFolderId
}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [open, setOpen] = useState(true)
  const [sending, setSending] = useState(false)

  const close = () => setOpen(false)

  const {loading, data} = useQuery(OBSERVER_ENROLLMENTS_QUERY, {
    variables: {
      courseId: assignment.courseId,
      studentIds: students.map(student => student.id)
    }
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

  const availableCriteria = filterCriteria.filter(criterion => criterion.shouldShow(assignment))
  const [showTable, setShowTable] = useState(false)
  const [selectedCriterion, setSelectedCriterion] = useState(availableCriteria[0])
  const [cutoff, setCutoff] = useState(0.0)
  const [attachments, setAttachments] = useState([])
  const [pendingUploads, setPendingUploads] = useState([])

  if (loading) {
    return <LoadingIndicator />
  }

  const sortedStudents = [...students].sort((a, b) => a.sortableName.localeCompare(b.sortableName))

  const handleCriterionSelected = (_e, {value}) => {
    const newCriterion = filterCriteria.find(criterion => criterion.value === value)
    if (newCriterion != null) {
      setSelectedCriterion(newCriterion)
    }
  }

  const handleSendButton = () => {
    if (pendingUploads.length) {
      // This notifies the AttachmentUploadSpinner to start spinning
      // which then calls onSend() when pendingUploads are complete.
      setSending(true)
    } else {
      onSend()
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
        <ModalHeader>
          <CloseButton
            placement="end"
            offset="small"
            onClick={close}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Compose Message')}</Heading>
        </ModalHeader>

        <ModalBody>
          <Flex alignItems="end">
            <Item>
              <SimpleSelect
                renderLabel={I18n.t('For students who…')}
                onChange={handleCriterionSelected}
                value={selectedCriterion.value}
              >
                {availableCriteria.map(criterion => (
                  <Option id={criterion.value} key={criterion.value} value={criterion.value}>
                    {criterion.title}
                  </Option>
                ))}
              </SimpleSelect>
            </Item>
            {selectedCriterion.requiresCutoff && (
              <Item margin="0 0 0 small">
                <NumberInput
                  value={cutoff}
                  onChange={(_e, value) => {
                    setCutoff(value)
                  }}
                  showArrows={false}
                  renderLabel={
                    <ScreenReaderContent>{I18n.t('Enter score cutoff')}</ScreenReaderContent>
                  }
                  width="5em"
                />
              </Item>
            )}
          </Flex>
          <br />
          <Flex>
            <Item>
              <Text weight="bold">{I18n.t('Send Message To:')}</Text>
            </Item>
            <Item margin="0 0 0 medium">
              <Checkbox
                defaultChecked
                label={
                  <Text weight="bold">
                    {I18n.t('%{studentCount} Students', {studentCount: students.length})}
                  </Text>
                }
              />
            </Item>
            <Item margin="0 0 0 medium">
              <Checkbox
                label={
                  <Text weight="bold">
                    {I18n.t('%{observerCount} Observers', {
                      observerCount: observerEnrollments.length
                    })}
                  </Text>
                }
              />
            </Item>
            <Item as="div" shouldGrow textAlign="end">
              <Link
                onClick={() => setShowTable(!showTable)}
                renderIcon={showTable ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
                iconPlacement="end"
                data-testid="show_all_recipients"
              >
                {showTable ? I18n.t('Hide all recipients') : I18n.t('Show all recipients')}
              </Link>
            </Item>
          </Flex>
          {showTable && (
            <Table caption={I18n.t('List of students and observers')}>
              <TableHead>
                <Row>
                  <ColHeader id="students">{I18n.t('Students')}</ColHeader>
                  <ColHeader id="observers">{I18n.t('Observers')}</ColHeader>
                </Row>
              </TableHead>
              <TableBody>
                {sortedStudents.map(student => (
                  <Row key={student.id}>
                    <Cell>
                      <FakeTag text={student.name} selected />
                    </Cell>
                    <Cell>
                      <Flex direction="row" margin="0 0 0 small" wrap="wrap">
                        {_.sortBy(
                          observersByStudentID[student.id] || [],
                          observer => observer.sortableName
                        ).map(observer => (
                          <Item key={observer._id}>
                            <FakeTag text={observer.name} />
                          </Item>
                        ))}
                      </Flex>
                    </Cell>
                  </Row>
                ))}
              </TableBody>
            </Table>
          )}

          <br />
          <TextInput renderLabel={I18n.t('Subject')} placeholder={I18n.t('Type Something…')} />
          <br />
          <TextArea
            height="200px"
            label={I18n.t('Message')}
            placeholder={I18n.t('Type your message here…')}
          />
          <AttachmentDisplay
            attachments={[...attachments, ...pendingUploads]}
            onDeleteItem={onDeleteAttachment}
            onReplaceItem={onReplaceAttachment}
          />
        </ModalBody>

        <ModalFooter>
          <Flex justifyItems="space-between" width="100%">
            <Item>
              <FileAttachmentUpload onAddItem={onAddAttachment} />
            </Item>
            <Item>
              <Flex>
                <Item>
                  <Button focusColor="info" color="primary-inverse" onClick={close}>
                    {I18n.t('Cancel')}
                  </Button>
                </Item>
                <Item margin="0 0 0 x-small">
                  <Button color="primary" onClick={handleSendButton}>
                    {I18n.t('Send')}
                  </Button>
                </Item>
              </Flex>
            </Item>
          </Flex>
        </ModalFooter>
      </Modal>
      <AttachmentUploadSpinner
        sendMessage={onSend}
        isMessageSending={sending}
        pendingUploads={pendingUploads}
      />
    </>
  )
}

export default MessageStudentsWhoDialog
