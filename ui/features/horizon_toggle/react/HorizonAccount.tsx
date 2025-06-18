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

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useState} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Checkbox} from '@instructure/ui-checkbox'
import {Menu} from '@instructure/ui-menu'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {reloadWindow} from '@canvas/util/globalUtils'

const I18n = createI18nScope('horizon_toggle_page')

export interface HorizonAccountProps {
  hasCourses: boolean
  accountId: string
  locked: boolean
}

export const HorizonAccount = ({hasCourses, accountId, locked}: HorizonAccountProps) => {
  const [termsAccepted, setTermsAccepted] = useState(false)

  const onSubmit = async () => {
    try {
      await doFetchApi({
        path: `/api/v1/accounts/${accountId}`,
        method: 'PUT',
        body: {
          id: accountId,
          account: {settings: {horizon_account: {value: true}}},
        },
      })

      reloadWindow()
    } catch (e) {
      showFlashError(I18n.t('Failed to switch to Canvas Career. Please try again.'))
    }
  }
  return (
    <View as="div">
      <Text as="p">
        {I18n.t(
          'Canvas Career is a new LMS experience for learning providers and learners at all career stages. It offers a simplified user interface along with powerful new features, including CRM and HRIS integration, program management, AI-driven actionable insights, and more!',
        )}
      </Text>
      <View background="secondary" as="div">
        <Flex direction="column" padding="small">
          <Heading level="h3">{I18n.t('Changes to Courses & Content')}</Heading>
          <Flex direction="column" gap="large">
            <Text as="p">
              {I18n.t(
                'Canvas Career offers a streamlined experience designed for individual learning. Discussions, Collaborations, and Outcomes are not included. To ensure seamless learning experience, all content must be within a module to be published. Assignments have been refined to support select submission types, providing a more tailored experience. Group assignments are not supported.',
              )}
            </Text>
            <Checkbox
              label={I18n.t(
                'I acknowledge that switching to Canvas Career will introduce changes to courses and content creation.',
              )}
              checked={termsAccepted}
              onChange={() => setTermsAccepted(!termsAccepted)}
              disabled={hasCourses || locked}
            />
          </Flex>
        </Flex>
        <Menu.Separator />
        <Flex padding="small" justifyItems="end">
          <Button
            color="primary"
            disabled={!termsAccepted || hasCourses || locked}
            onClick={onSubmit}
          >
            {I18n.t('Switch to Canvas Career')}
          </Button>
        </Flex>
      </View>
    </View>
  )
}
