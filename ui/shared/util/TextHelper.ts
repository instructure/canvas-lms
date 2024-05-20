//
// Copyright (C) 2012 - present Instructure, Inc.
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
//

import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape, {raw} from '@instructure/html-escape'
import TwitterText from 'twitter-text'

const I18n = useI18nScope('lib.text_helper')

export const AUTO_LINKIFY_PLACEHOLDER = 'linkplaceholder.example.com'

export function quoteClump(lines: string[]) {
  return `<div class='quoted_text_holder'> \
<a href='#' class='show_quoted_text_link'>${htmlEscape(
    I18n.t('quoted_text_toggle', 'show quoted text')
  )}</a> \
<div class='quoted_text' style='display: none;'> \
${raw(lines.join('\n'))} \
</div> \
</div>`
}

function replaceBetween(original: string, startIndex: number, endIndex: number, insertion: string) {
  return original.substring(0, startIndex) + insertion + original.substring(endIndex)
}

export function formatMessage(message: string) {
  // replace any links with placeholders so we don't escape them
  const links: string[] = []
  const placeholderBlocks: string[] = []
  TwitterText.extractUrlsWithIndices(message)
    .reverse()
    .forEach(({url, indices}) => {
      if (url === AUTO_LINKIFY_PLACEHOLDER) {
        placeholderBlocks.push(AUTO_LINKIFY_PLACEHOLDER)
      } else {
        let link = url
        if (!link.match(/^https?:\/\//)) {
          link = `http://${link}`
        }
        links.push(link)
        placeholderBlocks.push(`<a href='${htmlEscape(link)}'>${htmlEscape(url)}</a>`)
      }
      message = replaceBetween(message, indices[0], indices[1], AUTO_LINKIFY_PLACEHOLDER)
    })
  placeholderBlocks.reverse()

  // now escape html
  message = htmlEscape(message)

  // now put the links back in
  message = message.replace(
    new RegExp(AUTO_LINKIFY_PLACEHOLDER, 'g'),
    () => placeholderBlocks.shift() as string
  )

  // replace newlines
  message = message.replace(/\n/g, '<br />\n')

  // generate quoting clumps
  const processedLines: string[] = []
  let quoteBlock: string[] = []
  for (const line of Array.from(message.split('\n'))) {
    if (line.match(/^(&gt;|>)/)) {
      quoteBlock.push(line)
    } else {
      if (quoteBlock.length) {
        processedLines.push(quoteClump(quoteBlock))
      }
      quoteBlock = []
      processedLines.push(line)
    }
  }
  if (quoteBlock.length) {
    processedLines.push(quoteClump(quoteBlock))
  }
  return (message = processedLines.join('\n'))
}

export function delimit(number: number) {
  // only process real numbers
  if (Number.isNaN(number)) {
    return String(number)
  }

  // capture sign and then start working with the absolute value. don't
  // process infinities.
  const sign = number < 0 ? '-' : ''
  const abs = Math.abs(number)
  if (abs === Infinity) {
    return String(number)
  }

  // break out the integer portion and initialize the result to just the
  // decimal (if any)
  let integer = Math.floor(abs)
  let result = abs === integer ? '' : String(abs).replace(/^\d+\./, '.')

  // for each comma'd chunk, prepend to the result and remove from integer
  while (integer >= 1000) {
    const mod = String(integer).replace(/\d+(\d\d\d)$/, ',$1')
    integer = Math.floor(integer / 1000)
    result = mod + result
  }

  // integer is now either in [1, 999], or equal to 0 iff number in (-1, 1).
  // prepend it with the sign
  return sign + String(integer) + result
}

export function truncateText(
  string: string,
  options?: {
    max?: number
  }
) {
  if (options == null) {
    options = {}
  }
  const max = options.max != null ? options.max : 30
  const ellipsis = I18n.t('ellipsis', '...')
  const wordSeparator = I18n.t('word_separator', ' ')

  string = (string != null ? string : '').replace(/\s+/g, wordSeparator).trim()
  if (!string || string.length <= max) {
    return string
  }

  let truncateAt = 0
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const pos = string.indexOf(wordSeparator, truncateAt + 1)
    if (pos < 0 || pos > max - ellipsis.length) {
      break
    }
    truncateAt = pos
  }
  if (!truncateAt) {
    truncateAt = max - ellipsis.length
  } // first word > max, so we cut it

  return string.substring(0, truncateAt) + ellipsis
}

export function plainText(message: string) {
  // remove all html tags from the message returning only the text
  return message.replace(/(<([^>]+)>)/gi, '')
}
