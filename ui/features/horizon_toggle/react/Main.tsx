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

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {assignLocation} from '@canvas/util/globalUtils'
import {Alert} from '@instructure/ui-alerts'
import {HorizonAccount} from './HorizonAccount'
import {RevertAccount} from './RevertAccount'
import {Pill} from '@instructure/ui-pill'

const I18n = createI18nScope('horizon_toggle_page')

export interface MainProps {
  isHorizonAccount: boolean
  hasCourses: boolean
  accountId: string
  horizonAccountLocked: boolean
}

export const Main = ({
  isHorizonAccount,
  hasCourses,
  accountId,
  horizonAccountLocked,
}: MainProps) => {
  return (
    <View>
      {hasCourses && !isHorizonAccount && (
        <Alert variant="warning">
          {I18n.t(
            'Existing courses must be removed before making the switch to Canvas Career. To proceed, ensure all courses have been deleted or migrated.',
          )}
        </Alert>
      )}
      <Flex margin="medium 0 small 0" gap="x-small">
        <Heading level="h2">{I18n.t('Switch Learner Experience to Canvas Career')}</Heading>
        {isHorizonAccount && <Pill color="success">{I18n.t('Enabled')}</Pill>}
      </Flex>
      {isHorizonAccount ? (
        <RevertAccount accountId={accountId} isHorizonAccountLocked={horizonAccountLocked} />
      ) : (
        <HorizonAccount
          hasCourses={hasCourses}
          accountId={accountId}
          locked={horizonAccountLocked}
        />
      )}
    </View>
  )
}
