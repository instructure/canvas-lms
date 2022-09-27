/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import GradebookSettingsModal from './GradebookSettingsModal'

export default {
  title: 'Examples/Evaluate/Gradebook/GradebookSettingsModal',
  component: GradebookSettingsModal,
  args: {
    courseSettings: {
      allowFinalGradeOverride: true,
    },
    courseFeatures: {
      finalGradeOverrideEnabled: true,
    },
    courseId: '',
    locale: '',
    onClose: () => {},
    gradebookIsEditable: true,
    gradedLateSubmissionsExist: true,
    onCourseSettingsUpdated: () => {},
    onLatePolicyUpdate: () => {},
    onViewOptionsUpdated: () => {},
    postPolicies: {
      coursePostPolicy: {
        postManually: true,
      },
      setAssignmentPostPolicies: true,
      setCoursePostPolicy: true,
    },
    // The component uses a function prop to retrieve the viewOptions data
    // dynamically, but we specify the data itself here so it can be
    // customized
    viewOptions: {
      columnSortSettings: {
        criterion: 'name',
        direction: 'ascending',
      },
      hideTotal: true,
      showNotes: true,
      showUnpublishedAssignments: true,
      showSeparateFirstLastNames: true,
      hideAssignmentGroupTotals: true,
      statusColors: {
        dropped: '#FEF0E5',
        excused: '#E5F7E5',
        late: '#F3EFEA',
        missing: '#FEF7E5',
        resubmitted: '#E5F7F6',
      },
      viewUngradedAsZero: true,
    },
  },
}

function openGradebookSettingsModalRef(modal) {
  if (modal) modal.open()
}

const Template = args => {
  const {viewOptions, ...rest} = args
  return (
    <GradebookSettingsModal
      {...rest}
      loadCurrentViewOptions={() => viewOptions}
      ref={openGradebookSettingsModalRef}
    />
  )
}
export const Default = Template.bind({})
