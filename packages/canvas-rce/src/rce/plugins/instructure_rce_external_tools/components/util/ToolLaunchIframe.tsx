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

import React, {ForwardedRef, PropsWithChildren} from 'react'
import formatMessage from '../../../../../format-message'

/**
 * Provide an iframe for launching an LTI tool directly from the frontend.
 * Works just like all existing usages of the LTI <iframe> element, including
 * extracting a ref of the <iframe> directly and setting things on it later.
 */
const ToolLaunchIframe = React.forwardRef(
  (
    props: PropsWithChildren<React.IframeHTMLAttributes<HTMLIFrameElement>>,
    ref: ForwardedRef<HTMLIFrameElement>
  ) => {
    const postMessageForwardingFrameId = 'post_message_forwarding'

    return (
      <>
        <iframe
          title={formatMessage('External tool frame')}
          ref={ref}
          className="tool_launch"
          {...props}
          data-lti-launch="true"
        />

        <iframe
          id={postMessageForwardingFrameId}
          name={postMessageForwardingFrameId}
          title={postMessageForwardingFrameId}
          src="/post_message_forwarding"
          sandbox="allow-scripts allow-same-origin"
          style={{display: 'none'}}
        />
      </>
    )
  }
)

export default ToolLaunchIframe
