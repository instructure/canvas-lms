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

export const SUBJECT_ALLOW_LIST = [
  'lti.close',
  'lti.enableScrollEvents',
  'lti.fetchWindowSize',
  'lti.frameResize',
  'lti.hideRightSideWrapper',
  'lti.removeUnloadMessage',
  'lti.resourceImported',
  'lti.screenReaderAlert',
  'lti.scrollToTop',
  'lti.setUnloadMessage',
  'lti.showAlert',
  'lti.showModuleNavigation',
  'lti.capabilities',
  'lti.get_data',
  'lti.put_data',
  'lti.getPageContent',
  'lti.getPageSettings',
  'requestFullWindowLaunch',
  'toggleCourseNavigationMenu',
  'showNavigationMenu',
  'hideNavigationMenu',
] as const

export type SubjectId = (typeof SUBJECT_ALLOW_LIST)[number]

// These are handled elsewhere so ignore them
export const SUBJECT_IGNORE_LIST = [
  'A2ExternalContentReady',
  'LtiDeepLinkingResponse',
  'externalContentReady',
  'externalContentCancel',
  'mentions.NavigationEvent',
  'mentions.InputChangeEvent',
  'mentions.SelectionEvent',
  'betterchat.is_mini_chat',
  'defaultToolContentReady',
  'assignment.set_ab_guid',
] as const

/**
 * A mapping of message subject to a list of scopes that grant permission
 * for that subject.
 * A tool only needs one of the scopes listed to be granted access.
 * If a subject is not listed here, it is assumed to be allowed for all tools.
 */
export const SCOPE_REQUIRED_SUBJECTS: {[key: string]: string[]} = {
  'lti.getPageContent': ['https://canvas.instructure.com/lti/page_content/show'],
}
