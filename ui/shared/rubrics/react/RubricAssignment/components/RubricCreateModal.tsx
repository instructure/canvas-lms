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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {RubricForm} from '@canvas/rubrics/react/RubricForm'
import type {Rubric, RubricAssociation} from '../../types/rubric'
import type {SaveRubricResponse} from '../../../../../features/rubrics/queries/RubricFormQueries'

const I18n = createI18nScope('rubrics-form')

type RubricCreateModalProps = {
  isOpen: boolean
  rubric?: Rubric
  rubricAssociation?: RubricAssociation
  aiRubricsEnabled: boolean
  onDismiss: () => void
  onSaveRubric: (savedRubricResponse: SaveRubricResponse) => void
}
export const RubricCreateModal = ({
  isOpen,
  rubric,
  rubricAssociation,
  aiRubricsEnabled,
  onDismiss,
  onSaveRubric,
}: RubricCreateModalProps) => {
  const modalHeader = rubric ? I18n.t('Edit Rubric') : I18n.t('Create Rubric')

  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      size="fullscreen"
      label={modalHeader}
      shouldCloseOnDocumentClick={false}
      overflow="fit"
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading data-testid="rubric-assignment-create-modal">{modalHeader}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" width="80%" margin="0 auto">
          <RubricForm
            rubric={rubric}
            rubricAssociation={rubricAssociation}
            courseId={ENV.COURSE_ID}
            // @ts-expect-error
            assignmentId={ENV.ASSIGNMENT_ID}
            onCancel={onDismiss}
            onSaveRubric={onSaveRubric}
            // @ts-expect-error
            canManageRubrics={ENV.PERMISSIONS?.manage_rubrics}
            // @ts-expect-error
            criterionUseRangeEnabled={ENV.FEATURES.rubric_criterion_range}
            hideHeader={true}
            aiRubricsEnabled={aiRubricsEnabled}
            rootOutcomeGroup={ENV.ROOT_OUTCOME_GROUP}
            showAdditionalOptions={true}
          />
        </View>
      </Modal.Body>
    </Modal>
  )
}
