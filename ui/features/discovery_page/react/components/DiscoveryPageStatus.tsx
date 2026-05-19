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

import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {openWindow} from '@canvas/util/globalUtils'
import type {DiscoveryPageStatusProps} from '../types'

const I18n = createI18nScope('discovery_page')

export function DiscoveryPageStatus({active, viewUrl}: DiscoveryPageStatusProps) {
  return (
    <Flex direction="row" gap="x-small" alignItems="center" style={{whiteSpace: 'nowrap'}}>
      {active === true && <Pill color="success">{I18n.t('Enabled')}</Pill>}
      {active === false && <Pill color="info">{I18n.t('Disabled')}</Pill>}

      {viewUrl && (
        <Link
          href={viewUrl}
          variant="standalone-small"
          isWithinText={false}
          forceButtonRole={false}
          onClick={e => {
            e.preventDefault()
            openWindow(viewUrl, '_blank')
          }}
        >
          {I18n.t('View Discovery Page')}

          <ScreenReaderContent>{I18n.t('(opens in new tab)')}</ScreenReaderContent>
        </Link>
      )}
    </Flex>
  )
}
