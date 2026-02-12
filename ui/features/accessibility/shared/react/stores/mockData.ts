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

import {
  AccessibilityIssue,
  AccessibilityIssuesSummaryData,
  AccessibilityResourceScan,
  FormType,
  IssueWorkflowState,
  ResourceType,
  ResourceWorkflowState,
  ScanWorkflowState,
} from '../../../shared/react/types'

export const mockIssue1: AccessibilityIssue = {
  id: '1',
  ruleId: 'adjacent-links',
  element: 'a',
  displayName: 'Duplicate links',
  message:
    'These are two links that go to the same place. Turn them into one link to avoid repetition.',
  why: 'When two or more links are next to each other and lead to the same destination, screen readers interpret them as two separate links, even though the intent is usually displaying a single link. This creates unnecessary repetition and is confusing.',
  path: "./p/a[contains(concat(' ', normalize-space(@class), ' '), ' inline_disabled ')][1]",
  issueUrl: 'https://www.w3.org/TR/WCAG20-TECHS/H2.html',
  workflowState: IssueWorkflowState.Active,
  form: {
    type: FormType.Button,
    label: 'Merge links',
    value: 'false',
    undoText: 'Link merged',
    canGenerateFix: false,
  },
}

export const mockIssue2: AccessibilityIssue = {
  id: '2',
  ruleId: 'adjacent-links',
  element: 'a',
  displayName: 'Duplicate links',
  message:
    'These are two links that go to the same place. Turn them into one link to avoid repetition.',
  why: 'When two or more links are next to each other and lead to the same destination, screen readers interpret them as two separate links, even though the intent is usually displaying a single link. This creates unnecessary repetition and is confusing.',
  path: "./p/a[contains(concat(' ', normalize-space(@class), ' '), ' inline_disabled ')][1]",
  issueUrl: 'https://www.w3.org/TR/WCAG20-TECHS/H2.html',
  workflowState: IssueWorkflowState.Active,
  form: {
    type: FormType.Button,
    label: 'Merge links',
    value: 'false',
    undoText: 'Link merged',
    canGenerateFix: false,
  },
}

export const mockIssue3: AccessibilityIssue = {
  id: '3',
  ruleId: 'headings-sequence',
  element: 'h4',
  displayName: 'Skipped heading level',
  message:
    'This heading is more than one level below the previous heading.Heading levels should follow a logical order, for example Heading 2, then H3, then H4.',
  why: 'When heading levels are skipped (for example, from an H2 to an H4, skipping H3), screen reader users may have difficulty understanding the page structure. This creates a confusing outline of the page for assistive technology users.',
  path: './h4',
  issueUrl: 'https://www.w3.org/TR/WCAG20-TECHS/G141.html',
  workflowState: IssueWorkflowState.Active,
  form: {
    type: FormType.RadioInputGroup,
    label: 'How would you like to proceed?',
    value: 'Fix heading hierarchy',
    options: ['Fix heading level', 'Turn into a paragraph'],
    undoText: 'Heading hierarchy is now correct',
    canGenerateFix: false,
  },
}

export const mockIssue4: AccessibilityIssue = {
  id: '4',
  ruleId: 'adjacent-links',
  element: 'a',
  displayName: 'Duplicate links',
  message:
    'These are two links that go to the same place. Turn them into one link to avoid repetition.',
  why: 'When two or more links are next to each other and lead to the same destination, screen readers interpret them as two separate links, even though the intent is usually displaying a single link. This creates unnecessary repetition and is confusing.',
  path: "./p/a[contains(concat(' ', normalize-space(@class), ' '), ' inline_disabled ')][1]",
  issueUrl: 'https://www.w3.org/TR/WCAG20-TECHS/H2.html',
  workflowState: IssueWorkflowState.Active,
  form: {
    type: FormType.Button,
    label: 'Merge links',
    value: 'false',
    undoText: 'Link merged',
    canGenerateFix: false,
  },
}

export const mockIssue5: AccessibilityIssue = {
  id: '5',
  ruleId: 'headings-sequence',
  element: 'h4',
  displayName: 'Skipped heading level',
  message:
    'This heading is more than one level below the previous heading.Heading levels should follow a logical order, for example Heading 2, then H3, then H4.',
  why: 'When heading levels are skipped (for example, from an H2 to an H4, skipping H3), screen reader users may have difficulty understanding the page structure. This creates a confusing outline of the page for assistive technology users.',
  path: './h4',
  issueUrl: 'https://www.w3.org/TR/WCAG20-TECHS/G141.html',
  workflowState: IssueWorkflowState.Active,
  form: {
    type: FormType.RadioInputGroup,
    label: 'How would you like to proceed?',
    value: 'Fix heading hierarchy',
    options: ['Fix heading level', 'Turn into a paragraph'],
    undoText: 'Heading hierarchy is now correct',
    canGenerateFix: false,
  },
}

export const mockScan1: AccessibilityResourceScan = {
  id: 1,
  courseId: 14,
  resourceId: 1,
  resourceType: ResourceType.WikiPage,
  resourceName: 'Test Page 1',
  resourceWorkflowState: ResourceWorkflowState.Unpublished,
  resourceUpdatedAt: '2025-06-24T06:13:37-06:00',
  resourceUrl: '/courses/14/pages/1',
  workflowState: ScanWorkflowState.Completed,
  errorMessage: '',
  issueCount: 1,
  issues: [mockIssue1],
}

export const mockScan2: AccessibilityResourceScan = {
  id: 2,
  courseId: 14,
  resourceId: 2,
  resourceType: ResourceType.WikiPage,
  resourceName: 'Test Page 2',
  resourceWorkflowState: ResourceWorkflowState.Unpublished,
  resourceUpdatedAt: '2025-07-25T04:28:52-06:00',
  resourceUrl: '/courses/14/pages/2',
  workflowState: ScanWorkflowState.Completed,
  errorMessage: '',
  issueCount: 1,
  issues: [mockIssue2],
}

export const mockScan3: AccessibilityResourceScan = {
  id: 3,
  courseId: 14,
  resourceId: 57,
  resourceType: ResourceType.Assignment,
  resourceName: 'Assignment 1',
  resourceWorkflowState: ResourceWorkflowState.Published,
  resourceUpdatedAt: '2025-05-06T04:09:55-06:00',
  resourceUrl: '/courses/14/assignments/57',
  workflowState: ScanWorkflowState.Completed,
  errorMessage: '',
  issueCount: 0,
  issues: [],
}

export const mockScan4: AccessibilityResourceScan = {
  id: 4,
  courseId: 14,
  resourceId: 56,
  resourceType: ResourceType.Assignment,
  resourceName: 'Assignment 2',
  resourceWorkflowState: ResourceWorkflowState.Published,
  resourceUpdatedAt: '2025-06-18T04:16:21-06:00',
  resourceUrl: '/courses/14/assignments/56',
  workflowState: ScanWorkflowState.Completed,
  errorMessage: '',
  issueCount: 1,
  issues: [mockIssue3],
}

export const mockScan5: AccessibilityResourceScan = {
  id: 5,
  courseId: 14,
  resourceId: 21,
  resourceType: ResourceType.Assignment,
  resourceName: 'Assignment 3',
  resourceWorkflowState: ResourceWorkflowState.Published,
  resourceUpdatedAt: '2025-06-18T04:19:01-06:00',
  resourceUrl: '/courses/14/assignments/21',
  workflowState: ScanWorkflowState.Completed,
  errorMessage: '',
  issueCount: 2,
  issues: [mockIssue4, mockIssue5],
}

export const mockScanData: AccessibilityResourceScan[] = [
  mockScan1,
  mockScan2,
  mockScan3,
  mockScan4,
  mockScan5,
]

export const mockIssuesSummary1: AccessibilityIssuesSummaryData = {
  active: 61,
  resolved: 0,
  byRuleType: {
    'headings-sequence': 1,
    'adjacent-links': 50,
    'small-text-contrast': 10,
  },
}

export const mockIssuesSummary2: AccessibilityIssuesSummaryData = {
  active: 15,
  resolved: 0,
  byRuleType: {
    'img-alt': 5,
    'img-alt-length': 2,
    'headings-sequence': 3,
    'link-text': 4,
    'table-header': 1,
  },
}

export const mockEmptyIssuesSummary: AccessibilityIssuesSummaryData = {
  active: 0,
  resolved: 0,
  byRuleType: {},
}
