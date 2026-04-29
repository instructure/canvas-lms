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

import {useMutation} from '@tanstack/react-query'
import {generateAiAltText, AiAltTextRequest} from '../utilities/aiAltTextApi'
import {useRef, useEffect} from 'react'

export interface UseGenerateAiAltTextOptions {
  url: string | null
}

export const useGenerateAiAltText = (options: UseGenerateAiAltTextOptions) => {
  const abortControllerRef = useRef<AbortController | null>(null)

  const mutation = useMutation({
    mutationFn: async ({
      attachmentId,
      signal,
    }: {
      attachmentId: string | number
      signal?: AbortSignal
    }) => {
      if (!options.url) {
        throw Error('URL is missing for alt text generation')
      }

      const requestData: AiAltTextRequest = {
        attachment_id: attachmentId,
      }

      return generateAiAltText({
        url: options.url,
        requestData,
        signal,
      })
    },
  })

  const generate = async (attachmentId: string | number): Promise<string> => {
    if (!attachmentId) {
      throw new Error('Attachment ID is required')
    }

    abortControllerRef.current = new AbortController()

    const response = await mutation.mutateAsync({
      attachmentId,
      signal: abortControllerRef.current.signal,
    })

    return response.image.altText
  }

  useEffect(() => {
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort()
      }
    }
  }, [])

  return {
    isPending: mutation.isPending,
    generate,
  }
}
