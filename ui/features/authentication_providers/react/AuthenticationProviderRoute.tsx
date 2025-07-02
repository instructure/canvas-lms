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

import {Portal} from '@instructure/ui-portal'
import LDAPSettingsTest from './ldap/LDAPSettingsTest'
import {useParams} from 'react-router-dom'

type PortalMount = {
  mountPoint: HTMLElement
  component: JSX.Element
}

function ldapSettingsTest(portals: PortalMount[], accountId: string): void {
  const mountPoint = document.getElementById('ldap_settings_test_mount_point')

  if (!mountPoint) {
    return
  }

  portals.push({
    mountPoint,
    component: (
      <LDAPSettingsTest accountId={accountId} ldapIps={ENV.LDAP_SETTINGS_TEST?.ldap_ips} />
    ),
  })
}

export function Component() {
  const {accountId} = useParams<{accountId: string}>()
  const portals: Array<PortalMount> = []

  ldapSettingsTest(portals, accountId!)

  return (
    <>
      {portals.map(({mountPoint, component}) => (
        <Portal key={mountPoint.id} open={true} mountNode={mountPoint}>
          {component}
        </Portal>
      ))}
    </>
  )
}
