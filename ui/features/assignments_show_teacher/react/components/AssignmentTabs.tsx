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

import React, {useState} from 'react'
import AssignmentDetailsView from './AssignmentDetailsView'
import PeerReviewDetailsView from './PeerReviewDetailsView'
import {Tabs} from '@instructure/ui-tabs'
import {TeacherAssignmentType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'
import {type ViewOwnProps} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignment_tabs')

export default function AssignmentTabs({assignment}: {assignment: TeacherAssignmentType}) {
  const [selectedIndex, setSelectedIndex] = useState(0)

  const handleTabChange = (
    _event: React.MouseEvent<ViewOwnProps> | React.KeyboardEvent<ViewOwnProps>,
    tabData: {index: number; id?: string},
  ) => {
    setSelectedIndex(tabData.index)
  }

  return (
    <Tabs margin="large auto" padding="medium" onRequestTabChange={handleTabChange}>
      <Tabs.Panel
        data-testid="assignment-tab"
        renderTitle={I18n.t('Assignment')}
        isSelected={selectedIndex === 0}
      >
        <AssignmentDetailsView description={assignment.description} />
      </Tabs.Panel>
      <Tabs.Panel
        data-testid="peer-review-tab"
        renderTitle={I18n.t('Peer Review')}
        isSelected={selectedIndex === 1}
      >
        <PeerReviewDetailsView
          assignment={assignment}
          canEdit={ENV.CAN_EDIT_ASSIGNMENTS || false}
        />
      </Tabs.Panel>
    </Tabs>
  )
}
