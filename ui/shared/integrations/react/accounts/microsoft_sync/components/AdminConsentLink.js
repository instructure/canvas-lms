/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('account_settings_jsx_bundle')

function consentUrl({baseUrl, clientId, redirectUri, tenant}) {
  const url = new URL(`${baseUrl}/${tenant}/adminconsent`)
  url.searchParams.set('client_id', clientId)
  url.searchParams.set('redirect_uri', redirectUri)

  return url.href
}

const AdminConsentLink = props => {
  const url = consentUrl(props)

  return (
    <div>
      {props.enabled && (
        <>
          <View display="block" margin="small 0 0 0">
            <Text>
              {I18n.t(
                'After completing the above configuration, please use the following link to grant Canvas access to your Microsoft tenant:'
              )}
            </Text>
          </View>
          <View display="block">
            <Text>
              <Link href={url}>{I18n.t('Grant tenant access')}</Link>
            </Text>
          </View>
        </>
      )}
    </div>
  )
}

export default AdminConsentLink
