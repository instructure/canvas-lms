/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import { Flex } from '@instructure/ui-flex'
import { Checkbox } from '@instructure/ui-checkbox'

import React, { useState } from 'react'
import { useScope as createI18nScope } from '@canvas/i18n'
import TranslationOptions from './TranslationOptions'
import useTranslationDisplay from '../../hooks/useTranslationDisplay'

const I18n = createI18nScope('conversations_2')

interface TranslationControlsProps {
  inboxSettingsFeature: boolean
  signature: string
}

export interface Language {
  id: string
  name: string
}

const TranslationControls = (props: TranslationControlsProps) => {
  const [includeTranslation, setIncludeTranslation] = useState(false)

  const { handleIsPrimaryChange, primary } = useTranslationDisplay({
    signature: props.signature,
    inboxSettingsFeature: props.inboxSettingsFeature,
    includeTranslation
  })

  return (
    <>
      <Flex alignItems="start" padding="small small small">
        <Flex.Item>
          <Checkbox
            label={I18n.t('Include translated version of this message')}
            value="medium"
            variant="toggle"
            checked={includeTranslation}
            onChange={() => setIncludeTranslation(!includeTranslation)}
          />
        </Flex.Item>
      </Flex>
      {includeTranslation && (
        <TranslationOptions
          asPrimary={primary}
          onSetPrimary={handleIsPrimaryChange}
        />
      )}
    </>
  )
}

export default TranslationControls
