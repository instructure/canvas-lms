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

import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useTranslationStore} from '../../../hooks/useTranslationStore'

const I18n = createI18nScope('discussion_posts')

interface TranslationLoaderProps {
  id: string
}

const TranslationLoader = ({id}: TranslationLoaderProps) => {
  const entryInfo = useTranslationStore(state => state.entries[id])

  if (!entryInfo?.loading) {
    return null
  }

  return (
    <Flex justifyItems="start">
      <Flex.Item>
        <Spinner renderTitle={I18n.t('Translating')} size="x-small" />
      </Flex.Item>
      <Flex.Item margin="0 0 0 x-small">
        <Text>{I18n.t('Translating Text')}</Text>
      </Flex.Item>
    </Flex>
  )
}

export {TranslationLoader}
