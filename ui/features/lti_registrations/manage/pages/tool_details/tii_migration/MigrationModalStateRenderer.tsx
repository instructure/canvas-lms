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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('lti_registrations')

export type MigrationModalStateRendererProps = {
  state: 'loading' | 'error' | 'empty'
}

export const MigrationModalStateRenderer = ({state}: MigrationModalStateRendererProps) => {
  const content = {
    loading: <Text>{I18n.t('Loading migration data...')}</Text>,
    error: (
      <Alert variant="error" margin="0 0 medium 0">
        {I18n.t('Failed to load migration data. Please try again.')}
      </Alert>
    ),
    empty: <Text>{I18n.t('There is nothing to migrate.')}</Text>,
  }

  return (
    <View as="div" textAlign="center" padding="large" height="25rem">
      {content[state]}
    </View>
  )
}
