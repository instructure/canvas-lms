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

import {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import FindDialog from '@canvas/outcomes/backbone/views/FindDialog'
import OutcomeGroup from '@canvas/outcomes/backbone/models/OutcomeGroup'
import type {GroupOutcome} from '@canvas/global/env/EnvCommon'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {RubricFormFieldSetter} from '../types/RubricForm'
import {calcPointsPossible, stripPTags} from '../utils'

const I18n = createI18nScope('rubrics-form-outcome-dialog')

type UseOutcomeDialogProps = {
  criteriaRef: React.MutableRefObject<RubricCriterion[]>
  rootOutcomeGroup: GroupOutcome
  setRubricFormField: RubricFormFieldSetter
}
const useOutcomeDialog = ({
  criteriaRef,
  rootOutcomeGroup,
  setRubricFormField,
}: UseOutcomeDialogProps) => {
  const [isOutcomeDialogOpen, setIsOutcomeDialogOpen] = useState(false)

  const openOutcomeDialog = () => {
    setIsOutcomeDialogOpen(true)
  }

  const closeOutcomeDialog = () => {
    setIsOutcomeDialogOpen(false)
  }

  const createNewFindDialog = () => {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore - Backbone FindDialog constructor type mismatch
    return new FindDialog({
      title: I18n.t('Find Outcome'),
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore - Backbone OutcomeGroup constructor type mismatch
      selectedGroup: new OutcomeGroup(rootOutcomeGroup),
      useForScoring: true,
      shouldImport: false,
      disableGroupImport: true,
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore - Backbone OutcomeGroup constructor type mismatch
      rootOutcomeGroup: new OutcomeGroup(rootOutcomeGroup),
      url: '/outcomes/find_dialog',
      zIndex: 10000,
    })
  }

  useEffect(() => {
    if (!isOutcomeDialogOpen) {
      return
    }

    try {
      const dialog = createNewFindDialog()
      dialog?.show()
      ;(dialog as any).on('import', (outcomeData: any) => {
        const newOutcomeCriteria = {
          id: Date.now().toString(),
          points: outcomeData.attributes.points_possible,
          description: outcomeData.outcomeLink.outcome.title,
          longDescription: stripPTags(outcomeData.attributes.description),
          outcome: {
            displayName: outcomeData.attributes.display_name,
            title: outcomeData.outcomeLink.outcome.title,
          },
          ignoreForScoring: !outcomeData.useForScoring,
          masteryPoints: outcomeData.attributes.mastery_points,
          criterionUseRange: false,
          ratings: outcomeData.attributes.ratings,
          learningOutcomeId: outcomeData.outcomeLink.outcome.id,
        }
        const criteria = [...criteriaRef.current]
        // Check if the outcome has already been added to this rubric
        const hasDuplicateLearningOutcomeId = criteria.some(
          criterion => criterion.learningOutcomeId === newOutcomeCriteria.learningOutcomeId,
        )

        if (hasDuplicateLearningOutcomeId) {
          showFlashError(
            I18n.t('This Outcome has not been added as it already exists in this rubric.'),
          )()

          return
        }
        criteria.push(newOutcomeCriteria)

        setRubricFormField('pointsPossible', calcPointsPossible(criteria))
        setRubricFormField('criteria', criteria)
        dialog.cleanup()
      })
      setIsOutcomeDialogOpen(false)
    } catch (error) {
      showFlashError(I18n.t('Failed to open the outcome dialog'))()
    }
  }, [isOutcomeDialogOpen, rootOutcomeGroup, setRubricFormField])

  return {
    openOutcomeDialog,
    closeOutcomeDialog,
  }
}

export default useOutcomeDialog
