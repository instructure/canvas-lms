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

import {useState, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {DragDropContext as DragAndDrop, Droppable} from 'react-beautiful-dnd'
import type {DropResult} from 'react-beautiful-dnd'
import {RubricCriteriaRow} from './RubricCriteriaRow'
import {NewCriteriaRow} from './NewCriteriaRow'
import {RubricFormProps} from '../types/RubricForm'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'

const I18n = createI18nScope('rubrics-criteria-container')

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
  const [selectedLearningOutcomeId, setSelectedLearningOutcomeId] = useState<string>()
  const [movedCriterionId, setMovedCriterionId] = useState<string | null>(null)
  const [srAnnouncement, setSrAnnouncement] = useState<string>('')

  const handleMoveCriterion = useCallback(
    (index: number, moveValue: number) => {
      const newIndex = index + moveValue
      if (newIndex < 0 || newIndex >= rubricForm.criteria.length) return

      const criteriaList = [...rubricForm.criteria]
      const [movedItem] = criteriaList.splice(index, 1)
      criteriaList.splice(newIndex, 0, movedItem)

      // Track the moved criterion for focus management
      setMovedCriterionId(movedItem.id || null)

      // Announce the move to screen readers
      const newPosition = newIndex + 1
      setSrAnnouncement(I18n.t('Criterion moved to position %{position}', {position: newPosition}))

      // Clear the announcement after it's been read
      setTimeout(() => setSrAnnouncement(''), 1000)

      // Create a properly typed DropResult for react-beautiful-dnd
      const result: DropResult = {
        source: {index, droppableId: 'droppable-id'},
        destination: {index: newIndex, droppableId: 'droppable-id'},
        draggableId: movedItem.id || '',
        type: 'DEFAULT',
        mode: 'FLUID',
        reason: 'DROP',
        combine: null,
      }
      handleDragEnd(result)
    },
    [rubricForm.criteria, handleDragEnd],
  )

  return (
    <Flex.Item shouldGrow={true} shouldShrink={true} as="main" padding="xx-small">
      {/* Screen reader announcement region */}
      <ScreenReaderContent>
        <div aria-live="polite" aria-atomic="true">
          {srAnnouncement}
        </div>
      </ScreenReaderContent>
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
                        selectedLearningOutcomeId={selectedLearningOutcomeId}
                        selectLearningOutcome={setSelectedLearningOutcomeId}
                        showCriteriaRegeneration={showCriteriaRegeneration}
                        handleMoveCriterion={handleMoveCriterion}
                        criterionIndex={index}
                        isFirstCriterion={index === 0}
                        isLastCriterion={index === rubricForm.criteria.length - 1}
                        shouldFocus={criterion.id === movedCriterionId}
                        onFocused={() => setMovedCriterionId(null)}
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
