// Copyright (C) 2025 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {useEffect} from 'react'
import {captureException} from '@sentry/react'

type AdaChatbotProps = {
  onSubmit: () => void
}

function AdaChatbot({onSubmit}: AdaChatbotProps) {
  useEffect(() => {
    if (typeof window !== 'undefined' && (window as any).adaEmbed) {
      const adaEmbed = (window as any).adaEmbed
      const adaSettings = (window as any).adaSettings || {}

      const startTimeout = setTimeout(() => {
        onSubmit()
      }, 10000)

      try {
        // inject global adaSettings from partial (_ada_embed) into start options
        adaEmbed.start({
          ...adaSettings,
          handle: 'instructure-gen', // ensure handle remains explicit
          adaReadyCallback: () => {
            clearTimeout(startTimeout)
            adaEmbed.toggle()
            onSubmit()
          },
          toggleCallback: (isDrawerOpen: boolean) => {
            if (!isDrawerOpen) adaEmbed.stop()
          },
        })
      } catch (error) {
        clearTimeout(startTimeout)
        captureException(error)
        onSubmit()
      }
    } else {
      onSubmit()
    }
  }, [onSubmit])

  return null
}

export default AdaChatbot
