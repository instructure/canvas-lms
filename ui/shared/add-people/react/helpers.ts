/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import * as z from 'zod'
import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('add_people')

// parse the list of names entered by our user into an array
// separates entries on , or \n
// deals with entries like '"Last, First" email' where there's a common w/in quotes
export function parseNameList(nameList: string) {
  const names = []
  let iStart = 0
  let inQuote = false
  for (let i = 0; i < nameList.length; ++i) {
    const c = nameList.charAt(i)
    if (c === '"') {
      inQuote = !inQuote
    } else if ((c === ',' && !inQuote) || c === '\n') {
      const n = nameList.slice(iStart, i).trim()
      if (n.length) names.push(n)
      iStart = i + 1
    }
  }
  const n = nameList.slice(iStart).trim()
  if (n.length) names.push(n)
  return names
}

export function findEmailInEntry(entry: string) {
  const tokens = entry.split(/\s+/)
  const emailIndex = tokens.findIndex((t: string | string[]) => t.indexOf('@') >= 0)
  return tokens[emailIndex]
}

export const emailValidator = /.+@.+\..+/

// taken from https://emailregex.com/index.html
// lib/email_address_validator.rb looks like it uses RFC-5322 which this matches pretty well
const EMAIL_REGEX =
  /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/

const emailSchema = z.object({
  email: z
    .string()
    .min(1, I18n.t('Email is required.'))
    .regex(EMAIL_REGEX, I18n.t('Invalid email address.')),
})

export function validateEmailForNewUser(newUserInfo: {email: string}) {
  const result = emailSchema.safeParse(newUserInfo)
  return result.success ? null : result.error?.issues[0]?.message
}
