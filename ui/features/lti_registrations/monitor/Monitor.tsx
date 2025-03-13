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

import { getBasename } from '@canvas/lti-apps/utils/basename';
import React from 'react';
import { ltiUsageConfig, ltiUsageOptions } from './utils';

import { fetchToken } from './api/jwt';
import { fetchImpact } from './api/impact';

export const Monitor = () => {
  const root = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    let unmount = () => {}

    import('ltiusage/AppModule').then(module => {
      if(root.current !== null) {
        unmount = module.render({
          basename: getBasename('apps') + '/monitor',
          mountPoint: root.current,
          config: {
            ...ltiUsageConfig(),
            fetchToken,
            fetchImpact,
          },
          options: ltiUsageOptions()
        })
      } else {
        console.error('Could not find root element to mount lti usage')
      }
    })

    return () => unmount()
  }, [])

  return (
    <div ref={root}>
    </div>
  )
}