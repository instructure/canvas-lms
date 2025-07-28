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

import {useScope as createI18nScope} from '@canvas/i18n'
import {getBasename} from '@canvas/lti-apps/utils/basename'
import React from 'react'
import type {AccountId} from '../manage/model/AccountId'
import {fetchImpact} from './api/impact'
import {fetchLtiUsageToken} from './api/jwt'
import {ltiUsageConfig, ltiUsageOptions} from './utils'
import {useBreadcrumbStore} from '@canvas/breadcrumbs/useBreadcrumbStore'

const I18n = createI18nScope('lti_registrations.monitor')

export type MonitorProps = {
  accountId: AccountId
}

type Module = {
  render: (args: {
    basename: string
    mountPoint: HTMLElement
    config: {
      fetchToken: () => Promise<{token: string}>
      fetchImpact: typeof fetchImpact
    }
    breadcrumbStore: {
      appendBreadcrumb: (breadcrumb: {name: string; url: string}) => void
      popBreadcrumb: () => void
    }
    options: Record<string, any>
  }) => () => void
}

export const Monitor = ({accountId}: MonitorProps) => {
  const root = React.useRef<HTMLDivElement>(null)

  React.useEffect(() => {
    const store = useBreadcrumbStore.getState()
    let unmount = () => {}

    let addedBreadcrumbCount = 0

    import('ltiusage/AppModule').then((module: Module) => {
      if (root.current !== null) {
        unmount = module.render({
          basename: getBasename('apps') + '/monitor',
          mountPoint: root.current,
          config: {
            ...ltiUsageConfig(),
            fetchToken: () => fetchLtiUsageToken(accountId),
            fetchImpact,
          },
          breadcrumbStore: {
            appendBreadcrumb: breadcrumb => {
              // We only want to append the breadcrumb once
              store.appendBreadcrumb(breadcrumb)
              addedBreadcrumbCount += 1
            },
            popBreadcrumb: () => {
              if (addedBreadcrumbCount > 0) {
                addedBreadcrumbCount -= 1
                store.popBreadcrumb()
              }
            },
          },
          options: ltiUsageOptions(),
        })
      } else {
        console.error('Could not find root element to mount lti usage')
      }
    })

    return () => unmount()
  }, [])

  return <div ref={root}></div>
}
