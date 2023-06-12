// @ts-nocheck
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

import React from 'react'
import {render} from 'react-dom'
import type {GradebookSettingsModalProps} from './components/GradebookSettingsModal'

async function loadAssignmentPostingPolicyTray() {
  return (await import('../AssignmentPostingPolicyTray/index')).default
}

async function loadCurveGradesDialog() {
  return (await import('@canvas/grading/jquery/CurveGradesDialog')).default
}

async function loadGradeDetailTray() {
  return (await import('./components/SubmissionTray')).default
}

async function loadGradebookSettingsModal() {
  return (await import('./components/GradebookSettingsModal')).default
}

async function loadHideAssignmentGradesTray() {
  return (await import('@canvas/hide-assignment-grades-tray')).default
}

async function loadMessageStudentsWhoDialog() {
  return (await import('../shared/MessageStudentsWhoDialog')).default
}

async function loadMessageStudentsWithObserversDialog() {
  return (await import('@canvas/message-students-dialog/react/MessageStudentsWhoDialog')).default
}

async function loadPostAssignmentGradesTray() {
  return (await import('@canvas/post-assignment-grades-tray')).default
}

async function loadSetDefaultGradeDialog() {
  return (await import('@canvas/grading/jquery/SetDefaultGradeDialog')).default
}

const AsyncComponents = {
  loadAssignmentPostingPolicyTray,
  loadCurveGradesDialog,
  loadGradeDetailTray,
  loadGradebookSettingsModal,
  loadHideAssignmentGradesTray,
  loadMessageStudentsWhoDialog,
  loadMessageStudentsWithObserversDialog,
  loadPostAssignmentGradesTray,
  loadSetDefaultGradeDialog,

  async renderGradeDetailTray(props, $container) {
    const GradeDetailTray = await loadGradeDetailTray()
    render(<GradeDetailTray {...props} />, $container)
  },

  async renderGradebookSettingsModal(props: GradebookSettingsModalProps, $container: HTMLElement) {
    const GradebookSettingsModal = await loadGradebookSettingsModal()
    render(<GradebookSettingsModal key="grade_details_tray" {...props} />, $container)
  },
}

export default AsyncComponents
