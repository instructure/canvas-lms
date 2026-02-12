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

import {useMemo} from 'react'
import type {LanguageOption, Subtitle} from '../types'

interface UseLanguageFilteringParams {
  allLanguages: LanguageOption[]
  subtitles: Subtitle[]
}

interface UseLanguageFilteringReturn {
  availableLanguages: LanguageOption[]
}

/**
 * Filters available languages based on already-selected subtitles
 * Excludes non-inherited languages that are already selected
 */
export function useLanguageFiltering({
  allLanguages,
  subtitles,
}: UseLanguageFilteringParams): UseLanguageFilteringReturn {
  const availableLanguages = useMemo(() => {
    return allLanguages.filter(candidateLanguage => {
      // Keep languages that aren't selected yet, or are inherited (can be replaced)
      return !subtitles.find(
        subtitle => !subtitle.inherited && subtitle.locale === candidateLanguage.id,
      )
    })
  }, [allLanguages, subtitles])

  return {availableLanguages}
}
