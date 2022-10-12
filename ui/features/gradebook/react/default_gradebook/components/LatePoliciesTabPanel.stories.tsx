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
import LatePoliciesTabPanel from './LatePoliciesTabPanel'

export default {
  title: 'Examples/Evaluate/Gradebook/LatePoliciesTabPanel',
  component: LatePoliciesTabPanel,
  args: {
    latePolicy: {
      changes: {
        missingSubmissionDeductionEnabled: true,
        missingSubmissionDeduction: 3,
        lateSubmissionDeductionEnabled: true,
        lateSubmissionDeduction: 2,
        lateSubmissionInterval: 'day',
        lateSubmissionMinimumPercent: 20,
      },
      validationErrors: {
        missingSubmissionDeduction: '',
        lateSubmissionDeduction: '',
        lateSubmissionMinimumPercent: '',
      },
      data: {
        missingSubmissionDeductionEnabled: true,
        missingSubmissionDeduction: 3,
        lateSubmissionDeductionEnabled: true,
        lateSubmissionDeduction: 2,
        lateSubmissionInterval: 'day',
        lateSubmissionMinimumPercentEnabled: true,
        lateSubmissionMinimumPercent: 20,
      },
    },
    changeLatePolicy: () => {},
    gradebookIsEditable: true,
    locale: '',
    showAlert: false,
  },
}

const Template = args => <LatePoliciesTabPanel {...args} />
export const Default = Template.bind({})
