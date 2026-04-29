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

import React, {createContext, useContext, useState, useMemo, ReactNode} from 'react'

type PublishingCtx = {
  publishingInProgress: boolean
  startPublishing: () => void
  stopPublishing: () => void
}

const Ctx = createContext<PublishingCtx | null>(null)

export function PublishingProvider({children}: {children: ReactNode}) {
  const [publishingInProgress, setPublishingInProgress] = useState(false)

  const value = useMemo(
    () => ({
      publishingInProgress,
      startPublishing: () => setPublishingInProgress(true),
      stopPublishing: () => setPublishingInProgress(false),
    }),
    [publishingInProgress],
  )

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>
}

export function usePublishing() {
  const ctx = useContext(Ctx)
  if (!ctx) {
    console.warn('usePublishing must be used within PublishingProvider')
  }
  return ctx
}
