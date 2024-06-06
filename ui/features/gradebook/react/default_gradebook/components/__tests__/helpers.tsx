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

import {screen as _screen} from '@testing-library/dom'

export const getAutomaticallyApplyGradeForMissingSubmissionsCheckbox = (
  screen: typeof _screen
): HTMLInputElement => {
  return screen.getByRole('checkbox', {
    name: 'Automatically apply grade for missing submissions',
    hidden: true,
  })
}

export const getAutomaticallyApplyDeductionToLateSubmissionsCheckbox = (
  screen: typeof _screen
): HTMLInputElement => {
  return screen.getByRole('checkbox', {
    name: 'Automatically apply deduction to late submissions',
    hidden: true,
  })
}

export const getGradePercentageForMissingSubmissionsInput = (
  screen: typeof _screen
): HTMLInputElement => {
  return screen.getByRole('textbox', {name: 'Grade for missing submissions', hidden: true})
}

export const getLateSubmissionDeductionPercentInput = (
  screen: typeof _screen
): HTMLInputElement => {
  return screen.getByRole('textbox', {name: 'Late submission deduction', hidden: true})
}

export const getLateSubmissionDeductionIntervalInput = (
  screen: typeof _screen
): HTMLInputElement => {
  return screen.getByRole('combobox', {name: 'Deduction interval', hidden: true})
}

export const getLowestPossibleGradePercentInput = (screen: typeof _screen): HTMLInputElement => {
  return screen.getByRole('textbox', {name: 'Lowest possible grade', hidden: true})
}

export const getLatePoliciesTabPanelProps = () => {
  return {
    latePolicy: {
      changes: {},
      validationErrors: {},
    },
    changeLatePolicy: () => {},
    locale: 'en',
    gradebookIsEditable: true,
    showAlert: false,
  }
}

export const getDefaultLatePolicyData = () => {
  return {
    lateSubmissionDeductionEnabled: false,
    lateSubmissionDeduction: 0,
    lateSubmissionInterval: 'day',
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionMinimumPercent: 0,
    missingSubmissionDeductionEnabled: false,
    missingSubmissionDeduction: 100,
    newRecord: true,
  }
}

export const getLatePolicyData = () => {
  return {
    missingSubmissionDeductionEnabled: true,
    missingSubmissionDeduction: 0,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionDeduction: 0,
    lateSubmissionInterval: 'day',
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionMinimumPercent: 0,
  }
}

export const getActionMenuProps = () => {
  return {
    getAssignmentOrder: () => {},
    getStudentOrder: () => {},
    gradebookIsEditable: true,
    contextAllowsGradebookUploads: true,
    gradebookImportUrl: 'http://gradebookImportUrl',
    currentUserId: '42',
    gradebookExportUrl: 'http://gradebookExportUrl',
    postGradesLtis: [
      {
        id: '1',
        name: 'Pinnacle',
        onSelect: () => {},
      },
    ],
    postGradesFeature: {
      enabled: false,
      label: '',
      store: {},
      returnFocusTo: {
        focus: () => {},
      },
    },
    publishGradesToSis: {isEnabled: false},
    gradingPeriodId: '1234',
    updateExportState: () => {},
    setExportManager: () => {},
    lastExport: {progressId: '9000', workflowState: 'completed'},
    attachment: {
      id: '691',
      downloadUrl: 'http://downloadUrl',
      updatedAt: '2009-01-20T17:00:00Z',
      createdAt: '2009-01-20T17:00:00Z',
    },
  }
}

export function findOption(document: Document, label: string) {
  return [...document.querySelectorAll('[role=option]')].find(
    $el => $el.textContent?.trim() === label
  )
}
