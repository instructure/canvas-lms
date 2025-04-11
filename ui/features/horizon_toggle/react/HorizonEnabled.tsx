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
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useCallback, useState} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('horizon_toggle_page')

export const HorizonEnabled = () => {
  const [loading, setLoading] = useState(false)

  const onSubmit = useCallback(async () => {
    setLoading(true)
    const response = await doFetchApi<{success: boolean}>({
      path: `/courses/${ENV.COURSE_ID}/canvas_career_reversion`,
      method: 'POST',
    })
    if (response.json?.success) {
      window.location.reload()
    }
  }, [])

  return (
    <View as="div">
      <Pill color="success">{I18n.t('Enabled')}</Pill>
      <Flex gap="large" margin="large 0 0 0" direction="column">
        <View>
          <Heading level="h3">{I18n.t('Revert Course')}</Heading>
          <Text as="p">
            {I18n.t(
              'By reverting this course, all Canvas Career features will be disabled. Any deleted or altered content will remain as is and cannot be restored. Reverting a course will result in the loss of features, including the progress bar, notebook entries, AI Assist, Skillspace achievements, and estimated time metadata. These features will no longer be available after the course is reverted.',
            )}
          </Text>
        </View>
        <Flex gap="x-small" justifyItems="end">
          <Button color="primary" onClick={onSubmit} disabled={loading}>
            {I18n.t('Revert Course')}
          </Button>
        </Flex>
      </Flex>
    </View>
  )
}
