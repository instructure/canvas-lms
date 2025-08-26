/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {DragDropContext as DragAndDrop, Droppable} from 'react-beautiful-dnd'
import type {DropResult} from 'react-beautiful-dnd'
import {RubricCriteriaRow} from './RubricCriteriaRow'
import {NewCriteriaRow} from './NewCriteriaRow'
import {RubricFormProps} from '../types/RubricForm'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'

type RubricCriteriaRowsProps = {
  rubricForm: RubricFormProps
  isGenerating?: boolean
  showCriteriaRegeneration?: boolean
  handleDragEnd: (result: DropResult) => void
  deleteCriterion: (criterion: RubricCriterion) => void
  duplicateCriterion: (criterion: RubricCriterion) => void
  openCriterionModal: (criterion?: RubricCriterion) => void
  openOutcomeDialog: () => void
  onRegenerateCriterion?: (criterion: RubricCriterion, additionalPrompt: string) => void
}
export const RubricCriteriaContainer = ({
  rubricForm,
  isGenerating = false,
  showCriteriaRegeneration = false,
  handleDragEnd,
  deleteCriterion,
  duplicateCriterion,
  openCriterionModal,
  openOutcomeDialog,
  onRegenerateCriterion,
}: RubricCriteriaRowsProps) => {
  return (
    <Flex.Item shouldGrow={true} shouldShrink={true} as="main" padding="xx-small">
      <View as="div" margin="0 0 small 0">
        <DragAndDrop onDragEnd={handleDragEnd}>
          <Droppable droppableId="droppable-id">
            {provided => {
              return (
                <div
                  ref={provided.innerRef}
                  {...provided.droppableProps}
                  data-testid="rubric-criteria-container"
                >
                  {rubricForm.criteria.map((criterion, index) => {
                    return (
                      <RubricCriteriaRow
                        key={criterion.id}
                        criterion={criterion}
                        freeFormCriterionComments={rubricForm.freeFormCriterionComments}
                        hidePoints={rubricForm.hidePoints}
                        rowIndex={index + 1}
                        isGenerated={criterion.isGenerated}
                        nextIsGenerated={rubricForm.criteria[index + 1]?.isGenerated}
                        onDeleteCriterion={() => deleteCriterion(criterion)}
                        onDuplicateCriterion={() => duplicateCriterion(criterion)}
                        onEditCriterion={() => openCriterionModal(criterion)}
                        onRegenerateCriterion={onRegenerateCriterion}
                        isRegenerating={isGenerating}
                        showCriteriaRegeneration={showCriteriaRegeneration}
                      />
                    )
                  })}
                  {provided.placeholder}
                </div>
              )
            }}
          </Droppable>
        </DragAndDrop>
        <NewCriteriaRow
          rowIndex={rubricForm.criteria.length + 1}
          onEditCriterion={() => openCriterionModal()}
          onAddOutcome={() => openOutcomeDialog()}
        />
      </View>
    </Flex.Item>
  )
}
