/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'

export type LtiCustomVariable = {
  name: string
  description_key: string
  default_name?: string
  is_enabled: boolean
  status: 'added' | 'removed' | 'unchanged'
}

const SubstitutionVariables = [
  '$ResourceLink.id',
  '$ResourceLink.description',
  '$ResourceLink.title',
  '$ResourceLink.available.startDateTime',
  '$ResourceLink.available.endDateTime',
  '$ResourceLink.submission.endDateTime',
  '$User.id',
  '$User.image',
  '$User.username',
  '$Person.name.full',
  '$Person.name.display',
  '$Person.name.family',
  '$Person.name.given',
  '$Person.email.primary',
  '$Person.address.timezone',
  '$Person.sourcedId',
  '$Canvas.user.id',
  '$Canvas.user.globalId',
  '$Canvas.user.isRootAccountAdmin',
  '$Canvas.user.adminableAccounts',
  '$Canvas.user.loginId',
  '$Canvas.user.sisSourceId',
  '$Canvas.user.sisIntegrationId',
  '$Canvas.user.prefersHighContrast',
  '$Canvas.user.prefersDyslexicFont',
  '$Context.id',
  '$Context.title',
  '$Context.sourcedId',
  '$Context.id.history',
  '$Canvas.course.id',
  '$Canvas.course.name',
  '$Canvas.course.sisSourceId',
  '$Canvas.course.startAt',
  '$Canvas.course.endAt',
  '$Canvas.course.workflowState',
  '$Canvas.course.hideDistributionGraphs',
  '$Canvas.course.gradePassbackSetting',
  '$Canvas.course.sectionIds',
  '$Canvas.course.sectionSisSourceIds',
  '$Canvas.course.sectionRestricted',
  '$Canvas.course.previousContextIds',
  '$Canvas.course.previousContextIds.recursive',
  '$Canvas.course.previousCourseIds',
  '$Canvas.course.horizonMode',
  '$Canvas.assignment.id',
  '$Canvas.assignment.title',
  '$Canvas.assignment.description',
  '$Canvas.assignment.pointsPossible',
  '$Canvas.assignment.dueAt',
  '$Canvas.assignment.dueAt.iso8601',
  '$Canvas.assignment.unlockAt',
  '$Canvas.assignment.unlockAt.iso8601',
  '$Canvas.assignment.lockAt',
  '$Canvas.assignment.lockAt.iso8601',
  '$Canvas.assignment.published',
  '$Canvas.assignment.allowedAttempts',
  '$Canvas.assignment.submission.studentAttempts',
  '$Canvas.assignment.hideInGradebook',
  '$Canvas.assignment.omitFromFinalGrade',
  '$Canvas.assignment.lockdownEnabled',
  '$Canvas.assignment.anonymous_participants',
  '$Canvas.assignment.allDueAts.iso8601',
  '$Canvas.assignment.earliestEnrollmentDueAt.iso8601',
  '$Canvas.account.id',
  '$Canvas.account.name',
  '$Canvas.account.sisSourceId',
  '$Canvas.account.horizonMode',
  '$Canvas.rootAccount.id',
  '$Canvas.rootAccount.sisSourceId',
  '$Canvas.root_account.id',
  '$Canvas.root_account.global_id',
  '$Canvas.root_account.sisSourceId',
  '$Canvas.term.id',
  '$Canvas.term.name',
  '$Canvas.term.startAt',
  '$Canvas.term.endAt',
  '$Canvas.membership.roles',
  '$Canvas.membership.concludedRoles',
  '$Canvas.membership.permissions<>',
  '$Canvas.enrollment.enrollmentState',
  '$Membership.role',
  '$Canvas.api.domain',
  '$Canvas.api.baseUrl',
  '$Canvas.api.collaborationMembers.url',
  '$Canvas.module.id',
  '$Canvas.moduleItem.id',
  '$Canvas.file.media.id',
  '$Canvas.file.media.type',
  '$Canvas.file.media.duration',
  '$Canvas.file.media.size',
  '$Canvas.file.media.title',
  '$Canvas.file.usageRights.name',
  '$Canvas.file.usageRights.url',
  '$Canvas.file.usageRights.copyrightText',
  '$ToolConsumerInstance.guid',
  '$Canvas.shard.id',
  '$Canvas.css.common',
  '$Canvas.externalTool.global_id',
  '$Canvas.externalTool.url',
  '$Canvas.logoutService.url',
  '$Message.documentTarget',
  '$Message.locale',
  '$Canvas.masqueradingUser.id',
  '$Canvas.masqueradingUser.userId',
  '$com.instructure.User.observees',
  '$com.instructure.User.sectionNames',
  '$com.instructure.User.allRoles',
  '$com.instructure.User.instructureIdentityGlobalUserId',
  '$com.instructure.User.instructureIdentityOrganizationUserId',
  '$com.instructure.User.student_view',
  '$com.instructure.Person.name_sortable',
  '$com.instructure.Person.pronouns',
  '$com.instructure.PostMessageToken',
  '$com.instructure.Assignment.lti.id',
  '$com.instructure.Assignment.description',
  '$com.instructure.Assignment.allowedFileExtensions',
  '$com.instructure.Assignment.anonymous_grading',
  '$com.instructure.Assignment.restrict_quantitative_data',
  '$com.instructure.Submission.id',
  '$com.instructure.File.id',
  '$com.instructure.OriginalityReport.id',
  '$com.instructure.Context.globalId',
  '$com.instructure.Context.uuid',
  '$com.instructure.Course.integrationId',
  '$com.instructure.Course.groupIds',
  '$com.instructure.Course.gradingScheme',
  '$com.instructure.Group.id',
  '$com.instructure.Group.name',
  '$com.instructure.Editor.contents',
  '$com.instructure.Editor.selection',
  '$com.instructure.RCS.app_host',
  '$com.instructure.RCS.service_jwt',
  '$com.instructure.Observee.sisIds',
  '$com.instructure.brandConfigJSON',
  '$com.instructure.brandConfigJSON.url',
  '$com.instructure.brandConfigJS.url',
  '$com.instructure.contextLabel',
  '$com.Instructure.membership.roles',
  '$com.instructure.Account.instructureIdentityOrganizationId',
  '$CourseOffering.sourcedId',
  '$CourseSection.sourcedId',
  '$CourseGroup.id',
  '$Activity.id.history',
  '$LineItem.resultValue.max',
  '$ToolProxyBinding.memberships.url',
  '$ToolProxyBinding.custom.url',
  '$ToolProxy.custom.url',
  '$ToolConsumerProfile.url',
  '$LtiLink.custom.url',
  '$vnd.instructure.User.uuid',
  '$vnd.instructure.User.current_uuid',
  '$vnd.Canvas.root_account.uuid',
  '$vnd.instructure.Course.uuid',
  '$vnd.Canvas.Person.email.sis',
  '$vnd.Canvas.submission.url',
  '$vnd.Canvas.submission.history.url',
  '$vnd.Canvas.OriginalityReport.url',
  '$Caliper.url',
  '$Canvas.xapi.url',
  '$Canvas.xuser.allRoles',
  '$Canvas.account.decimal_separator',
  '$Canvas.account.thousand_separator',
  '$com.instructure.instui_nav',
  '$com.instructure.user.lti_1_1_id.history',
  '$com.instructure.Tag.id',
  '$com.instructure.Tag.name',
] as const

export type SubstitutionVariable = (typeof SubstitutionVariables)[number]

/**
 * Returns true if the given string is a recognized substitution variable in Canvas.
 * @param variable
 * @returns
 */
export const isSubstitutionVariable = (variable: string): variable is SubstitutionVariable =>
  SubstitutionVariables.includes(variable as SubstitutionVariable)

/**
 * Extracts substitution variables from a given set of custom fields.
 * Only returns values that are recognized substitution variables in Canvas
 * using @link {isSubstitutionVariable}.
 * @param customFields
 * @returns
 */
const extractFromCustomFields = (
  customFields: Record<string, string> | null | undefined,
): SubstitutionVariable[] => {
  if (!customFields) {
    return []
  }

  return Object.values(customFields).filter(isSubstitutionVariable)
}

/**
 * Extracts all custom variable substitutions from an LTI configuration.
 * Parses custom_fields from the base configuration, launch_settings, and all placements
 * to find variables that start with "$".
 *
 * @param config The internal LTI configuration to parse
 * @returns Array of custom variables found in the configuration, with descriptions where available
 */
export function extractSubstitutionVariables(
  config: InternalLtiConfiguration | undefined,
): Set<SubstitutionVariable> {
  if (!config) {
    return new Set()
  }

  // Extract from base custom_fields
  const base = extractFromCustomFields(config.custom_fields)

  // Extract from launch_settings custom_fields
  const launch_settings = extractFromCustomFields(config.launch_settings?.custom_fields)

  const placements = config.placements.flatMap(placement =>
    extractFromCustomFields(placement.custom_fields),
  )

  return new Set([...base, ...launch_settings, ...placements])
}

/**
 * Compares two configurations to determine which custom variables were added, removed, or unchanged.
 *
 * @param oldConfig The original configuration
 * @param newConfig The updated configuration
 * @returns Array of custom variables with their status (added/removed/unchanged)
 */
export function compareSubstitutionVariables(
  oldConfig: InternalLtiConfiguration,
  newConfig: InternalLtiConfiguration | undefined,
): {
  unchanged: Set<SubstitutionVariable>
  added: Set<SubstitutionVariable>
  removed: Set<SubstitutionVariable>
} {
  if (!newConfig) {
    return {
      unchanged: extractSubstitutionVariables(oldConfig),
      added: new Set(),
      removed: new Set(),
    }
  } else {
    const oldVariables = extractSubstitutionVariables(oldConfig)
    const newVariables = extractSubstitutionVariables(newConfig)

    return {
      unchanged: new Set([...oldVariables].filter(x => newVariables.has(x))),
      added: new Set([...newVariables].filter(x => !oldVariables.has(x))),
      removed: new Set([...oldVariables].filter(x => !newVariables.has(x))),
    }
  }
}
