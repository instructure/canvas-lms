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

import React, { useEffect, useMemo, useState } from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import uid from '@instructure/uid'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import { itemTypeToApiURL } from '@canvas/context-modules/differentiated-modules/utils/assignToHelper'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('shared_due_dates_react_mastery_paths_toggle_in_course_pacing')

const MAX_PAGES = 10
const makeCardId = () => uid('assign-to-card', 12)

const MasteryPathToggle = ({ overrides, useCards, onSync, courseId, itemType, itemContentId }) => {
  const masteryPathsEnabled = useMemo(() => {
    if (!useCards) {
      return overrides.some(override => override.noop_id == "1")
    } else {
      return overrides.some(override => override.selectedAssigneeIds.includes("mastery_paths"))
    }
  }, [overrides, useCards])

  const [hasFetched, setHasFetched] = useState(false)

  useEffect(() => {
    if (!useCards || !courseId || !itemType || !itemContentId) {
      return
    }

    const fetchAllPages = async () => {

      let url = itemTypeToApiURL(courseId, itemType, itemContentId)
      const allResponses = []

      try {
        let pageCount = 0
        let args = {
          path: url,
          params: {per_page: 100},
        }
        while (url && pageCount < MAX_PAGES) {
          const response = await doFetchApi(args)
          allResponses.push(response.json)
          url = response.link?.next?.url || null
          args = {
            path: url,
          }
          pageCount++
        }

        const combinedResponse = allResponses.reduce(
          (acc, response) => ({
            ...response,
            overrides: [...(acc.overrides || []), ...(response.overrides || [])]
          }),
          {},
        )

        const cards = []

        combinedResponse.overrides.forEach((override) => {
          const filteredStudents = override.students
            const studentOverrides =
              filteredStudents?.map(student => ({
                id: `student-${student.id}`,
                value: student.name,
                group: 'Students',
              })) ?? []
            const initialAssigneeOptions = studentOverrides
            const defaultOptions = studentOverrides.map(option => option.id)
            if (override.noop_id) {
              defaultOptions.push('mastery_paths')
            }
            if (override.course_section_id) {
              defaultOptions.push(`section-${override.course_section_id}`)
              initialAssigneeOptions.push({
                id: `section-${override.course_section_id}`,
                value: override.title,
                group: 'Sections',
              })
            }
            if (override.course_id) {
              defaultOptions.push('everyone')
            }
            if (override.group_id) {
              defaultOptions.push(`group-${override.group_id}`)
              initialAssigneeOptions.push({
                id: `group-${override.group_id}`,
                value: override.title,
                groupCategoryId: override.group_category_id,
                group: 'Groups',
              })
            }
          cards.push({
            key: makeCardId(),
            isValid: true,
            hasAssignees: true,
            due_at: override.due_at,
            original_due_at: override.due_at,
            unlock_at: override.unlock_at,
            lock_at: override.lock_at,
            selectedAssigneeIds: defaultOptions,
            defaultOptions,
            initialAssigneeOptions,
            overrideId: override.id,
            contextModuleId: override.context_module_id,
            contextModuleName: override.context_module_name,
          })
        })

        onSync(cards)
      } catch(e) {
        showFlashError()()
        throw e
      } finally {
        setHasFetched(true)
      }
    }

    !hasFetched && fetchAllPages()

  }, [useCards, itemContentId, courseId, itemType])

  const onChange = (evt) => {
    if (evt.target.checked) {
      if (useCards) {
        const overridesWithMasteryPath = [
          {
            key: makeCardId(),
            isValid: true,
            hasAssignees: true,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            due_at: null,
            unlock_at: null,
            lock_at: null,
            contextModuleId: null,
            contextModuleName: null,
            selectedAssigneeIds: ["mastery_paths"],
            isEdited: true,
            hasInitialOverride: false,
            highlightCard: true
          },
          ...overrides.filter(({selectedAssigneeIds}) => !selectedAssigneeIds.includes("everyone"))
        ]
        onSync(overridesWithMasteryPath)
      } else {
        const overridesWithMasteryPath = [
          {
            noop_id: "1",
            stagedOverrideId: uid(),
            title: I18n.t('Mastery Paths'),
            rowKey: overrides.length
          },
          ...overrides.filter(({course_section_id}) => course_section_id !== "0")
        ]
        onSync(overridesWithMasteryPath)
      }
    } else {
      if (useCards) {
        const withoutMasteryPaths = overrides.filter(({selectedAssigneeIds}) => !selectedAssigneeIds.includes('mastery_paths'))

        if (!withoutMasteryPaths.some(({selectedAssigneeIds}) => selectedAssigneeIds.includes("everyone"))) {
          withoutMasteryPaths.push({
            key: makeCardId(),
            isValid: true,
            hasAssignees: true,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            due_at: null,
            unlock_at: null,
            lock_at: null,
            contextModuleId: null,
            contextModuleName: null,
            selectedAssigneeIds: ["everyone"],
            isEdited: true,
            hasInitialOverride: false,
            highlightCard: true
          })
        }
        onSync(withoutMasteryPaths)
      } else {
        const withoutMasteryPaths = overrides.filter(({noop_id}) => noop_id !== "1")

        if (!withoutMasteryPaths.some(({course_section_id}) => course_section_id === "0")) {
          withoutMasteryPaths.push({
            due_at: null,
            lock_at: null,
            unlock_at: null,
            course_section_id: "0",
            due_at_overridden: false,
            all_day: false,
            all_day_date: null,
            unlock_at_overridden: false,
            lock_at_overridden: false
          })
        }
        onSync(withoutMasteryPaths)
      }
    }
  }

  return (
    <View as="div" margin="medium 0 0 0" data-testid="MasteryPathToggle">
      <Checkbox
        variant="toggle"
        checked={masteryPathsEnabled}
        onChange={onChange}
        label={masteryPathsEnabled ? I18n.t('Enabled') : I18n.t('Disabled')}
        id="mastery-path-toggle"
      />
    </View>
  )
}

export default MasteryPathToggle
