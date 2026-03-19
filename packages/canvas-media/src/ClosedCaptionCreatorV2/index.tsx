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

import {useEffect, useState} from 'react'
import getTranslations from '../getTranslations'
import {type ClosedCaptionPanelProps, ClosedCaptionPanelV2} from './ClosedCaptionPanelV2'

/**
 * Wrapper component that loads translations before rendering the panel
 * Maintains API compatibility with original ClosedCaptionCreator
 */
export default function ClosedCaptionCreatorV2(props: ClosedCaptionPanelProps) {
  const [translationsLoaded, setTranslationsLoaded] = useState(false)

  useEffect(() => {
    getTranslations(props.userLocale)
      .catch(() => {
        // Ignore and fallback to English
      })
      .finally(() => {
        setTranslationsLoaded(true)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  if (translationsLoaded) {
    return <ClosedCaptionPanelV2 {...props} />
  } else {
    return <div />
  }
}

// Export ClosedCaptionPanel separately for testing and direct usage
export {ClosedCaptionPanelV2}
