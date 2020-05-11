/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from 'i18n!assignments_bulk_edit'
import React from 'react'
import {arrayOf, bool, func, number} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CanvasInlineAlert from 'jsx/shared/components/CanvasInlineAlert'
import {originalDateField} from './utils'
import {AssignmentShape} from './BulkAssignmentShape'

BulkEditHeader.propTypes = {
  assignments: arrayOf(AssignmentShape).isRequired,
  startingSave: bool.isRequired,
  jobRunning: bool.isRequired,
  jobCompletion: number.isRequired,
  jobSuccess: bool.isRequired,
  onSave: func.isRequired,
  onCancel: func.isRequired,
  onOpenBatchEdit: func.isRequired
}

export default function BulkEditHeader({
  assignments,
  startingSave,
  jobRunning,
  jobCompletion,
  jobSuccess,
  onSave,
  onCancel,
  onOpenBatchEdit
}) {
  function renderProgressValue({valueNow}) {
    return <Text>{I18n.t('%{percent}%', {percent: valueNow})}</Text>
  }

  const anyAssignmentsEdited = (() => {
    const overrides = assignments.flatMap(a => a.all_dates)
    return overrides.some(override =>
      [
        originalDateField('due_at'),
        originalDateField('unlock_at'),
        originalDateField('lock_at')
      ].some(originalField => override.hasOwnProperty(originalField))
    )
  })()

  const validationErrorsExist = (() => {
    return assignments.some(assignment =>
      assignment.all_dates.some(override => Object.keys(override.errors || {}).length > 0)
    )
  })()

  const selectedAssignmentsCount = assignments.filter(a => a.selected).length

  return (
    <>
      <Heading level="h2">{I18n.t('Edit Assignment Dates')}</Heading>
      <Flex as="div" padding="0 0 medium 0">
        <Flex.Item shouldGrow>
          {jobRunning && (
            <View as="div" maxWidth="500px">
              <ProgressBar
                screenReaderLabel={I18n.t('Saving assignment dates progress')}
                valueNow={jobCompletion}
                renderValue={renderProgressValue}
              />
              <CanvasInlineAlert liveAlert screenReaderOnly variant="info">
                {I18n.t('Saving assignment dates progress: %{percent}%', {
                  percent: jobCompletion
                })}
              </CanvasInlineAlert>
            </View>
          )}
        </Flex.Item>
        {ENV.FEATURES.assignment_bulk_edit_phase_2 && (
          <Flex.Item margin="0 0 0 small">
            <Text>
              {I18n.t(
                {one: '%{count} assignment selected', other: '%{count} assignments selected'},
                {count: selectedAssignmentsCount}
              )}
            </Text>
          </Flex.Item>
        )}
        {ENV.FEATURES.assignment_bulk_edit_phase_2 && (
          <Flex.Item>
            <Button
              margin="0 0 0 small"
              onClick={onOpenBatchEdit}
              interaction={selectedAssignmentsCount > 0 ? 'enabled' : 'disabled'}
            >
              {I18n.t('Batch Edit')}
            </Button>
          </Flex.Item>
        )}
        <Flex.Item>
          <Button margin="0 0 0 small" onClick={onCancel}>
            {jobSuccess ? I18n.t('Close') : I18n.t('Cancel')}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            margin="0 0 0 small"
            variant="primary"
            interaction={
              startingSave || jobRunning || !anyAssignmentsEdited || validationErrorsExist
                ? 'disabled'
                : 'enabled'
            }
            onClick={onSave}
          >
            {startingSave || jobRunning ? I18n.t('Saving...') : I18n.t('Save')}
          </Button>
        </Flex.Item>
      </Flex>
    </>
  )
}
