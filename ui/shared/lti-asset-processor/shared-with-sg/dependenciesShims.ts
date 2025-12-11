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

/**
 * Most of the ltiAssetProcessor code, which provides LTI Asset Reports, is
 * duplicated in SpeedGrader. The replicated/ directory should be kept identical to
 * the code in canvas-lms by making the changes in here or in Canvas and using
 * the asset-processor-speedgrader-sync script to copy the changed files to the other place
 * and run linting.
 *
 * This file provides dependencies used by the shared code which need to be
 * different between Canvas and this repo.
 *
 * Generally, SpeedGrader coding linting standards are stricter, so it may be
 * easiest to make changes in the SpeedGrader repo and copy them to Canvas.
 *
 * You can use the asset-processors-code-copy script in interop-team-scripts
 * to easily copy the replicated directory from one repo to another (and patch
 * the I18n import, see script for details)
 *
 * See also canvas-lms/doc/lti/18_asset_reports.md
 */

// Re-export gql from gqlShim to avoid circular dependencies
// (gqlShim doesn't import from graphqlQueryHooks like this file does)
import {gql, type GqlTemplateStringType} from './gqlShim'

// Values returned by the graphql queries replicated/queries/*.ts and
// replicated/mutations/*.ts must be compatible with these types.
import {
  type GetLtiAssetProcessorsResult,
  type GetLtiAssetReportsResult,
} from '../model/LtiAssetReport'

// use* hooks must return tanstack query results where the data is of the above
// types. They must also show the alert messages
// (getLtiAssetProcessorsErrorMessage, getLtiAssetReportsErrorMessage) in case
// of error.
import {useLtiAssetProcessors, useLtiAssetReports} from '../react/hooks/graphqlQueryHooks'
import {useResubmitLtiAssetReports} from '../react/hooks/useResubmitLtiAssetReports'
import {useResubmitDiscussionNotices} from '../react/hooks/useResubmitDiscussionNotices'
import DateHelper from '@canvas/datetime/dateHelper'

const useFormatDateTime = () => DateHelper.formatDatetimeForDiscussions

export {
  gql,
  type GqlTemplateStringType,
  type GetLtiAssetProcessorsResult,
  type GetLtiAssetReportsResult,
  useLtiAssetProcessors,
  useLtiAssetReports,
  useResubmitLtiAssetReports,
  useResubmitDiscussionNotices,
  useFormatDateTime,
}
