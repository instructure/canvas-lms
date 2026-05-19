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

import {useTranslation} from '@canvas/i18next'

import {Button, CloseButton} from '@instructure/ui-buttons'

import {useMedia} from 'react-use'

import styles from './ImmersiveViewBackButton.module.css'

export function ImmersiveViewBackButton() {
  const {t} = useTranslation('media_immersive_view')
  const isTablet = !useMedia('(min-width: 769px)')

  const handleClick = useCallback(() => {
    window.history.back()
  }, [])

  return isTablet ? (
    <CloseButton size="medium" screenReaderLabel={t('Go Back to Course')} onClick={handleClick} />
  ) : (
    <div className={styles.noShrink}>
      <Button color="primary" onClick={handleClick}>
        {t('Go Back to Course')}
      </Button>
    </div>
  )
}
