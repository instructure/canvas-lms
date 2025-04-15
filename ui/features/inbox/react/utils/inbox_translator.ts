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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {signatureSeparator, translationSeparator} from './constants'
import type React from 'react'

/**
 * Arguments to the translation process
 * */
interface TranslateArgs {
  subject?: string
  body?: string
  srcLang?: string
  tgtLang: string
  signature?: string
}

/**
 * Translate the message based on the parameters
 * */
export async function translateMessage(args: TranslateArgs) {
  if (!args.body) {
    return
  }

  let payload: string = ''

  if (args.subject) {
    payload = payload.concat(args.subject + ':\n')
  }

  // TODO: We possibly don't need the signature because the useEffect should just glom it onto the body as the body changes.
  if (args.body) {
    // Check for the signature first.
    const bodySplit = args.body.split(signatureSeparator)
    payload = payload.concat(bodySplit[0])
  }

  // Translate the payload, then with that text.
  return translateText(args, payload)
}

export async function translateText(args: TranslateArgs, text: string): Promise<string> {
  const apiPath = `/courses/${ENV.course_id}/translate/paragraph`

  try {
    const {json} = await doFetchApi({
      method: 'POST',
      path: apiPath,
      body: {
        inputs: {
          tgt_lang: args.tgtLang,
          text,
        },
      },
    })

    return (json as {translated_text: string}).translated_text
  } catch (e) {
    // @ts-expect-error
    const response = await e.response.json()
    const error = new Error()
    Object.assign(error, {...response})
    throw error
  }
}

/**
 * Strip the signature from the body, so that it can be added back later.
 * */
export function stripSignature(body: string): string {
  if (!body.includes(signatureSeparator)) {
    return body
  }
  return body.split(signatureSeparator)[0]
}

/**
 * Set the modal body properly, with signature and body text.
 * */
export function updateTranslatedModalBody(
  translatedText: string,
  isPrimary: boolean,
  bodySetter: React.Dispatch<React.SetStateAction<string>>,
  activeSignature?: string,
  newBody?: string,
) {
  bodySetter(prevBody => {
    let message
    if (typeof newBody !== 'undefined') {
      message = [translatedText, newBody]
    } else {
      message = [translatedText, stripSignature(prevBody)]
    }
    if (!isPrimary) {
      message = message.reverse()
    }

    message = message.join(translationSeparator)
    if (activeSignature) {
      message = [message, activeSignature].join(signatureSeparator)
    }

    return message
  })
}
