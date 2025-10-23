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

import {useCallback} from 'react'

import {useScope as createI18nScope} from '@canvas/i18n'

import {Button, CloseButton} from '@instructure/ui-buttons'

import {useMedia} from 'react-use'

// @ts-expect-error
import styles from './ImmersiveViewBackButton.module.css'

const I18n = createI18nScope('media_immersive_view')

export function ImmersiveViewBackButton() {
  const isTablet = !useMedia('(min-width: 769px)')

  const handleClick = useCallback(() => {
    window.history.back()
  }, [])

  return isTablet ? (
    <CloseButton size="medium" screenReaderLabel={I18n.t('Close')} onClick={handleClick} />
  ) : (
    <div className={styles.noShrink}>
      <Button color="primary" onClick={handleClick}>
        {I18n.t('Back to Course')}
      </Button>
    </div>
  )
}
