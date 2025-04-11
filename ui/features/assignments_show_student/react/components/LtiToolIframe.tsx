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

import {useState, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import ToolLaunchIframe from '@canvas/external-tools/react/components/ToolLaunchIframe'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import {defaultFetchOptions, getPrefetchedXHR} from '@canvas/util/xhr'
import {useScope as createI18nScope} from '@canvas/i18n'
import {LtiToolIframeProps, LtiConfig} from '../../ltiTool'
import {getConfigBasedOnToolId} from '../helpers/ltiConfigHelper'

const I18n = createI18nScope('assignments_2_student_content')

export const LtiToolIframe = ({submission, assignment}: LtiToolIframeProps) => {
  const [ltiConfig, setLtiConfig] = useState<LtiConfig | null>(null)
  const showTool = ENV.LTI_TOOL === 'true'
  const showSubmissionDetailsLink =
    submission.state === 'graded' && assignment.submissionTypes?.includes('external_tool')

  useEffect(() => {
    const getLTILaunchConfig = async () => {
      const definitionUrl = encodeURI(
        `/api/v1/courses/${ENV.COURSE_ID}/lti_apps/launch_definitions?placements[]=assignment_selection&only_visible=true`,
      )
      const response =
        (await getPrefetchedXHR(definitionUrl)) ||
        (await fetch(definitionUrl, defaultFetchOptions()))
      if (response.ok) {
        const data = await response.json()
        setLtiConfig(getConfigBasedOnToolId(data))
      }
    }

    getLTILaunchConfig()
  }, [])

  if (!showTool && !showSubmissionDetailsLink && !ltiConfig) {
    return null
  }

  const launchURL = `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}/tool_launch`
  const submissionDetailsURL = `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}/submissions/${ENV.current_user_id}`

  return (
    <>
      {showSubmissionDetailsLink && (
        <View margin="0 0 small 0" as="div">
          <Link data-testid="view-submission-link" href={submissionDetailsURL}>
            {I18n.t('View Submission')}
          </Link>
        </View>
      )}
      {showTool && (
        <ToolLaunchIframe
          allow={iframeAllowances()}
          src={launchURL}
          style={
            ltiConfig
              ? {
                  height: ltiConfig.placements.assignment_selection.selection_height,
                  width: ltiConfig.placements.assignment_selection.selection_width,
                }
              : {}
          }
          data-testid="lti-external-tool"
          title={I18n.t('Tool content')}
          allowFullScreen
        />
      )}
    </>
  )
}
