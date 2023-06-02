/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('instructure')

// toSentence is needed because Intl.ListFormat is not supported
// in Safari versions in MacOS prior to Big Sur

// I18n.toSentence could also be used if we upgraded i18n-js to 4.x

class ListFormat {
  format(array: string[]) {
    const options = {
      words_connector: I18n.t('#support.array.words_connector'),
      two_words_connector: I18n.t('#support.array.two_words_connector'),
      last_word_connector: I18n.t('#support.array.last_word_connector'),
    }

    switch (array.length) {
      case 0:
        return ''
      case 1:
        return '' + array[0]
      case 2:
        return array[0] + options.two_words_connector + array[1]
      default:
        return (
          array.slice(0, -1).join(options.words_connector) +
          options.last_word_connector +
          array[array.length - 1]
        )
    }
  }
}

const listFormatter = new ListFormat()

export default listFormatter
