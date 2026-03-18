/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useState, useEffect} from 'react'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {RubricAssignmentContainer} from '@canvas/rubrics/react/RubricAssignment'
import {View, type ViewProps} from '@instructure/ui-view'
import {Rubric, RubricAssociation} from '@canvas/rubrics/react/types/rubric'
import {AssignmentRubric} from '@canvas/rubrics/react/RubricAssignment/queries'

const I18n = createI18nScope('discussion_topics_post')

type DisplayRubricModalProps = {
  aiRubricsEnabled: boolean
  assignmentId: string
  assignmentPointsPossible?: number
  canManageRubrics: boolean
  courseId: string
  currentUserId: string
  isOpen: boolean
  rubric?: AssignmentRubric
  rubricAssociation?: RubricAssociation
  onClose: () => void
}

const customContainerStyles: Partial<ViewProps> = {
  borderColor: 'primary',
  borderWidth: '0',
  padding: 'none',
  margin: '0',
}

export const DisplayRubricModal = ({
  aiRubricsEnabled,
  assignmentId,
  assignmentPointsPossible,
  canManageRubrics,
  courseId,
  currentUserId,
  isOpen,
  rubric,
  rubricAssociation,
  onClose,
}: DisplayRubricModalProps) => {
  const [assignmentRubric, setAssignmentRubric] = useState(rubric)
  const [assignmentRubricAssociation, setAssignmentRubricAssociation] = useState(rubricAssociation)

  useEffect(() => {
    setAssignmentRubric(rubric)
  }, [rubric])

  useEffect(() => {
    setAssignmentRubricAssociation(rubricAssociation)
  }, [rubricAssociation])

  const handleRubricChange = (
    updatedRubric: Rubric | undefined,
    updatedRubricAssociation: RubricAssociation | undefined,
  ) => {
    setAssignmentRubric(updatedRubric)
    setAssignmentRubricAssociation(updatedRubricAssociation)
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onClose}
      label={I18n.t('Assignment Rubric Details')}
      shouldCloseOnDocumentClick={false}
      data-testid="assignment-rubric-modal"
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Assignment Rubric Details')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" textAlign="center" maxWidth="48em">
          <RubricAssignmentContainer
            aiRubricsEnabled={aiRubricsEnabled}
            assignmentId={assignmentId}
            assignmentRubric={assignmentRubric}
            assignmentPointsPossible={assignmentPointsPossible}
            assignmentRubricAssociation={assignmentRubricAssociation}
            canManageRubrics={canManageRubrics}
            containerStyles={{...customContainerStyles}}
            courseId={courseId}
            currentUserId={currentUserId}
            rubricSelfAssessmentFFEnabled={false}
            onRubricChange={handleRubricChange}
          />
        </View>
      </Modal.Body>
    </Modal>
  )
}
