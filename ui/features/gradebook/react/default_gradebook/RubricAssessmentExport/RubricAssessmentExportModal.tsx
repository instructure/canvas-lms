/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import useStore from '../stores'

import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useAssignmentRubricAssessments} from './useAssignmentRubricAssessments'

const I18n = createI18nScope('rubrics-export')

export const RubricAssessmentExportModal = () => {
  const {rubricAssessmentExportModalProps, toggleRubricAssessmentExportModal} = useStore()

  const {isOpen, assignment, studentsCount} = rubricAssessmentExportModalProps

  const rubricAssessments = useAssignmentRubricAssessments({assignmentId: assignment?.id})
  const completed = rubricAssessments?.assignment.rubricAssessment.assessmentsCount ?? 0
  const nonCompleted = studentsCount - completed

  const closeModal = () => {
    toggleRubricAssessmentExportModal(false)
  }

  const [filter, setFilter] = useState('all')

  const renderCloseButton = () => (
    <CloseButton placement="end" offset="small" onClick={closeModal} screenReaderLabel="Close" />
  )

  if (!assignment || studentsCount === 0) {
    return null
  }

  const downloadLink = `/courses/${assignment.courseId}/assignments/${assignment.id}/rubric/assessments/export?filter=${filter}`

  return (
    <Modal
      open={isOpen}
      onDismiss={closeModal}
      label={I18n.t('Bulk Download Rubrics')}
      shouldCloseOnDocumentClick={true}
      size="small"
      data-testid="export-rubric-modal"
    >
      <Modal.Header>
        {renderCloseButton()}
        <Heading>{I18n.t('Bulk Download Rubrics')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" padding="small 0 small 0" gap="small">
          <Flex.Item>
            <Text>
              {I18n.t(`Please identify the rubrics you wish to download for `)}
              <b>{`"${assignment.name}"`}</b>
            </Text>
          </Flex.Item>
          <Flex.Item padding="xx-small">
            <RadioInputGroup
              onChange={(_, value) => setFilter(value)}
              name="filter"
              defaultValue="all"
              description={<ScreenReaderContent>{I18n.t(`filter`)}</ScreenReaderContent>}
            >
              <RadioInput
                key="all"
                value="all"
                label={`${I18n.t('All Students')} (${studentsCount})`}
              />
              <RadioInput
                key="completed"
                value="completed"
                label={`${I18n.t('Has Assessment')} (${completed})`}
                disabled={completed === 0}
              />
              <RadioInput
                key="non-completed"
                value="non-completed"
                label={`${I18n.t('Not Assessed')} (${nonCompleted})`}
                disabled={nonCompleted === 0}
              />
            </RadioInputGroup>
          </Flex.Item>
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={closeModal} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button color="primary" href={downloadLink} onClick={closeModal}>
          {I18n.t('Download')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
