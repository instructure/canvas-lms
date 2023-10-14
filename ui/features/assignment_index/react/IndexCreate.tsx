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
import $ from 'jquery'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {IconAddSolid} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('assignmentsIndexView')

export type IndexCreateProps = {
  newAssignmentUrl: string
  quizLtiEnabled: boolean
  manageAssignmentAddPermission: boolean
}
export default ({
  newAssignmentUrl,
  quizLtiEnabled,
  manageAssignmentAddPermission,
}: IndexCreateProps) => {
  return (
    <>
      {manageAssignmentAddPermission && (
        <Flex gap="small" wrap="wrap">
          <>
            {quizLtiEnabled && (
              <Button
                id="new_quiz_lti"
                data-testid="new_quiz_button"
                renderIcon={IconAddSolid}
                href={newAssignmentUrl + '?quiz_lti'}
              >
                {I18n.t('New Quiz')}
              </Button>
            )}
            <Button
              data-testid="new_group_button"
              renderIcon={IconAddSolid}
              onClick={e => {
                const hiddenInput = $('[data-view=addGroup]')
                hiddenInput.click()
              }}
            >
              {I18n.t('New Group')}
            </Button>
            <Button
              data-testid="new_assignment_button"
              renderIcon={IconAddSolid}
              color="primary"
              href={newAssignmentUrl}
            >
              {I18n.t('New Assignment')}
            </Button>
          </>
        </Flex>
      )}
    </>
  )
}
