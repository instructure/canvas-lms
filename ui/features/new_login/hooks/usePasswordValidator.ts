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

import type {PasswordPolicy} from '../types'

export const usePasswordValidator = (passwordPolicy?: PasswordPolicy) => {
  if (!passwordPolicy) {
    return (): string | null => null
  }

  return (password: string | undefined): string | null => {
    if (!password) return 'too_short'

    const {
      minimumCharacterLength = 0,
      maximumCharacterLength = Infinity,
      requireNumberCharacters,
      requireSymbolCharacters,
      maxRepeats,
      maxSequence,
    } = passwordPolicy

    if (password.length < minimumCharacterLength) {
      return 'too_short'
    }

    if (password.length > maximumCharacterLength) {
      return 'too_long'
    }

    if (requireNumberCharacters && !/\d/.test(password)) {
      return 'no_digits'
    }

    if (requireSymbolCharacters && !/[!@#$%^&*()_+\-=[\]{}|;:'"<>,.?/]/.test(password)) {
      return 'no_symbols'
    }

    if (maxRepeats) {
      const repeatedCharRegex = new RegExp(`(.)\\1{${maxRepeats},}`)
      if (repeatedCharRegex.test(password)) {
        return 'repeated'
      }
    }

    if (maxSequence) {
      for (let i = 0; i <= password.length - maxSequence; i++) {
        const segment = password.slice(i, i + maxSequence)
        if (isKeyboardSequence(segment)) {
          return 'sequence'
        }
      }
    }

    return null
  }
}

/**
 * Check if a string is part of predefined keyboard sequences
 * @param str String to check
 * @returns True if the string matches a keyboard sequence
 */
const isKeyboardSequence = (str: string): boolean => {
  const SEQUENCES = [
    'abcdefghijklmnopqrstuvwxyz',
    '`1234567890-=',
    'qwertyuiop[]\\',
    "asdfghjkl;'",
    'zxcvbnm,./',
  ]
  const reversedSequences = SEQUENCES.map(seq => seq.split('').reverse().join(''))
  const allSequences = SEQUENCES.concat(reversedSequences)

  return allSequences.some(seq => seq.includes(str))
}
