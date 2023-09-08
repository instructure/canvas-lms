/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import type JQuery from 'jquery'
import type {
  ProvisionalGrade,
  RubricAssessment,
  SubmissionOriginalityData,
  SubmissionState,
} from '@canvas/grading/grading.d'
import type {
  Assignment,
  Attachment,
  AttachmentData,
  Enrollment,
  GradingPeriod,
  Student,
  Submission,
  SubmissionComment,
} from '../../../api.d'
import PostPolicies from '../react/PostPolicies/index'
import AssessmentAuditTray from '../react/AssessmentAuditTray'

interface Window {
  jsonData: {
    assignment: Assignment
    context: {
      active_course_sections: CourseSection[]
      enrollments: Enrollment[]
      grading_periods: GradingPeriod[]
      students: Student[]
    }
    grades_published_at: string
    GROUP_GRADING_MODE: boolean
    id: string
    moderated_grading: boolean
    submissions: Submission[]
    title: string
  }
}

export type StudentWithSubmission = Student & {
  id: string
  anonymous_id: string
  anonymous_name_position: number
  provisional_crocodoc_urls: ProvisionalCrocodocUrl[]
  rubric_assessments: RubricAssessment[]
  submission: Submission & {
    currentSelectedIndex: number
    // TODO: remove the any
    submission_history: any | Submission[]
    provisional_grades: ProvisionalGrade[]
    show_grade_in_dropdown: boolean
  }
  submission_state: SubmissionState
  needs_provisional_grade: boolean
  avatar_path: string
  index: number
}

export type SpeedGrader = {
  resolveStudentId: (studentId: string | null) => string | undefined
  handleGradeSubmit: (event, use_existing_score: boolean) => void
  addCommentDeletionHandler: (commentElement: JQuery, comment: SubmissionComment) => void
  addCommentSubmissionHandler: (commentElement: JQuery, comment: SubmissionComment) => void
  addSubmissionComment: (comment?: boolean) => void
  onProvisionalGradesFetched: (data: {
    needs_provisional_grade: boolean
    provisional_grades: ProvisionalGrade[]
    updated_at: string
    final_provisional_grade: string
  }) => void
  anyUnpostedComment: () => boolean
  assessmentAuditTray?: AssessmentAuditTray | null
  attachmentIframeContents: (attachment: Attachment) => string
  beforeLeavingSpeedgrader: (event: BeforeUnloadEvent) => void
  changeToSection: (sectionId: string) => void
  currentDisplayedSubmission: () => Submission
  currentIndex: () => number
  currentStudent: StudentWithSubmission
  domReady: () => void
  resetReassignButton: () => void
  updateHistoryForCurrentStudent: (behavior: 'push' | 'replace') => void
  fetchProvisionalGrades: () => void
  displayExpirationWarnings: (
    aggressiveWarnings: number[],
    count: number,
    crocodocMessage: string
  ) => void
  setGradeReadOnly: (readOnly: boolean) => void
  showStudent: () => void
  initialVersion?: number
  parseDocumentQuery: () => any
  getOriginalRubricInfo: () => any
  totalStudentCount: () => number
  formatGradeForSubmission: (grade: string) => string
  skipRelativeToCurrentIndex: (skip: number) => void
  initComments: () => void
  renderAttachment: (attachment: Attachment) => void
  goToStudent: (studentIdentifier: any, historyBehavior?: 'push' | 'replace' | null) => void
  handleGradingError: (error: GradingError) => void
  handleStatePopped: (event: PopStateEvent) => void
  getStudentNameAndGrade: (student?: StudentWithSubmission) => string
  handleStudentChanged: (historyBehavior: 'push' | 'replace' | null) => void
  isStudentConcluded: (currentStudent: string) => boolean
  postPolicies?: PostPolicies
  reassignAssignment: () => void
  refreshFullRubric: () => void
  selectProvisionalGrade: (gradeId: string, existingGrade?: boolean) => void
  setCurrentStudentRubricAssessments: () => void
  setReadOnly: (readOnly: boolean) => void
  renderSubmissionPreview: () => void
  renderComment: (commentData: SubmissionComment, incomingOpts?: any) => JQuery
  showSubmission: () => void
  showSubmissionDetails: () => void
  tearDownAssessmentAuditTray: () => void
  renderLtiLaunch: (
    $iframe_holder: JQuery,
    lti_retrieve_url: string,
    submission: Partial<Submission>
  ) => void
  setCurrentStudentAvatar: () => void
  setActiveProvisionalGradeFields: (options?: {
    grade?: null | Partial<ProvisionalGrade>
    label?: string
  }) => void
  handleSubmissionSelectionChange: () => void
  isGradingTypePercent: () => boolean
  jsonReady: () => void
  setInitiallyLoadedStudent: () => void
  setupGradeLoadingSpinner: () => void
  next: () => void
  prev: () => void
  refreshSubmissionsToView: () => void
  renderProvisionalGradeSelector: (options?: {showingNewStudent?: boolean}) => void
  revertFromFormSubmit: (options?: {draftComment?: boolean; errorSubmitting?: boolean}) => void
  setUpAssessmentAuditTray: () => void
  shouldParseGrade: () => boolean
  showDiscussion: () => void
  showRubric: (options?: {validateEnteredData?: boolean}) => void
  updateSelectMenuStatus: (student: any) => void
  renderCommentAttachment: (
    comment: SubmissionComment,
    attachmentData: AttachmentData | Attachment,
    options: any
  ) => JQuery
  updateStatsInHeader: () => void
  setOrUpdateSubmission: (submission: any) => {
    rubric_assessments: {
      id: string
    }[]
  }
  generateWarningTimings: (count: number) => number[]
  emptyIframeHolder: (element?: JQuery) => void
  showGrade: () => void
  toggleFullRubric: (opt?: string) => void
  updateWordCount: (count?: number | null) => void
  populateTurnitin: (
    submission: Partial<Submission>,
    assetString: string,
    turnitinAsset_: SubmissionOriginalityData,
    $turnitinScoreContainer: JQuery,
    $turnitinInfoContainer_: JQuery,
    isMostRecent: boolean
  ) => void
  populateVeriCite: (
    submission: Partial<Submission>,
    assetString: string,
    vericiteAsset: SubmissionOriginalityData,
    $vericiteScoreContainer: JQuery,
    $vericiteInfoContainer: JQuery,
    isMostRecent: boolean
  ) => void
  current_prov_grade_index?: string
  getGradeToShow: (submission: Submission) => Grade
  setupProvisionalGraderDisplayNames: () => void
  handleProvisionalGradeSelected: (params: {
    selectedGrade?: {
      provisional_grade_id: string
    }
    isNewGrade: boolean
  }) => void
  compareStudentsBy: (
    f: (student1: StudentWithSubmission) => number
  ) => (studentA: StudentWithSubmission, studentB: StudentWithSubmission) => any
  plagiarismIndicator: (options: {
    plagiarismAsset: SubmissionOriginalityData
    reportUrl?: null | string
    tooltip: string
  }) => JQuery
  loadSubmissionPreview: (
    attachment: Attachment | null,
    submission: Partial<Submission> | null
  ) => void
  hasUnsubmittedRubric: (originalRubric: any) => boolean
  refreshGrades: (
    callback: (submission: Submission) => void,
    retry?: (
      submission: Submission,
      originalSubmission: Submission,
      numRequests: number
    ) => boolean,
    retryDelay?: number
  ) => void
  setState: (state: any) => void
}

export type Grade = {
  entered: string
  pointsDeducted?: any
  adjusted?: any
}

export type GradingError = {
  errors?: {
    error_code:
      | 'ASSIGNMENT_LOCKED'
      | 'MAX_GRADERS_REACHED'
      | 'PROVISIONAL_GRADE_INVALID_SCORE'
      | 'PROVISIONAL_GRADE_MODIFY_SELECTED'
  }
}

type GradeLoadingStateMap = {
  [userId: string]: boolean
}

export type GradeLoadingData = {
  currentStudentId: string
  gradesLoading: GradeLoadingStateMap
}

export type ProvisionalCrocodocUrl = {
  attachment_id: string
}

export type CourseSection = {
  id: string
  name: string
}
