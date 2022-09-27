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

import ApplyScoreToUngradedModal from './ApplyScoreToUngradedModal'
import React from 'react'

export default {
  title: 'Examples/Evaluate/Gradebook/Apply Score to Ungraded Modal',
  component: ApplyScoreToUngradedModal,
  args: {
    assignmentGroup: null,
    open: true,
  },
  argTypes: {
    onApply: {action: 'HI GUYS'},
    onClose: {action: 'HHHD'},
  },
}

const Template = args => <ApplyScoreToUngradedModal {...args} />

export const AllAssignments = Template.bind({})

export const SpecificAssignmentGroup = Template.bind({})

SpecificAssignmentGroup.args = {
  ...AllAssignments.args,
  assignmentGroup: {
    id: '100',
    name: 'My Assignment Group',
  },
}
