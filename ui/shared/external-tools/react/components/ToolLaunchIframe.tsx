/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {IframeHTMLAttributes} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'

const I18n = createI18nScope('external_toolsModalLauncher')

/**
 * Provide an iframe for launching an LTI tool directly from the frontend.
 * Works just like all existing usages of the LTI \<iframe\> element, including
 * extracting a ref of the \<iframe\> directly and setting things on it later.
 *
 * IMPORTANT: The `allow` attribute is set at render time (not via setAttribute after mount)
 * because browsers require certain permissions (microphone, camera) to be present at initial
 * iframe creation time. Setting these permissions later via setAttribute is ignored by
 * modern browsers for security reasons.
 */
const ToolLaunchIframe = React.forwardRef<
  HTMLIFrameElement,
  IframeHTMLAttributes<HTMLIFrameElement>
>((props, ref) => {
  return (
    <iframe
      title={I18n.t('External tool frame')}
      ref={ref}
      className="tool_launch"
      allow={iframeAllowances()}
      {...props}
      data-lti-launch="true"
    />
  )
})

export default ToolLaunchIframe
