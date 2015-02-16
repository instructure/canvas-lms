#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'i18n!lib.text_helper'
  'str/htmlEscape'
], (I18n, htmlEscape) ->

  AUTO_LINKIFY_PLACEHOLDER = "LINK-PLACEHOLDER"
  AUTO_LINKIFY_REGEX = ///
    \b
    (                                            # Capture 1: entire matched URL
      (?:
        https?://                                # http or https protocol
        |                                        # or
        www\d{0,3}[.]                            # "www.", "www1.", "www2." … "www999."
        |                                        # or
        [a-z0-9.\-]+[.][a-z]{2,4}/               # looks like domain name followed by a slash
      )

      (?:
        [^\s()<>]+                               # Run of non-space, non-()<>
        |                                        # or
        \([^\s()<>]*\)                           # balanced parens, single level
      )+

      (?:
        \([^\s()<>]*\)                           # balanced parens, single level
        |                                        # or
        [^\s`!()\[\]{};:'".,<>?«»“”‘’]           # End with: not a space or one of these punct chars
      )
    ) | (
      LINK-PLACEHOLDER
    )
  ///gi

  th = 
    quoteClump: (lines) ->
      "<div class='quoted_text_holder'>
        <a href='#' class='show_quoted_text_link'>#{htmlEscape I18n.t("quoted_text_toggle", "show quoted text")}</a>
        <div class='quoted_text' style='display: none;'>
          #{$.raw lines.join "\n"}
        </div>
      </div>"
  
    formatMessage: (message) ->
      # replace any links with placeholders so we don't escape them
      links = []
      placeholderBlocks = []
      message = message.replace AUTO_LINKIFY_REGEX, (match, i) ->
        placeholderBlocks.push(if match == AUTO_LINKIFY_PLACEHOLDER
            AUTO_LINKIFY_PLACEHOLDER
          else
            link = match
            link = "http://" + link if link[0..3] == 'www.'
            link = encodeURI(link).replace(/'/g, '%27')
            links.push link
            "<a href='#{htmlEscape(link)}'>#{htmlEscape(match)}</a>"
        )
        AUTO_LINKIFY_PLACEHOLDER
  
      # now escape html
      message = htmlEscape message
  
      # now put the links back in
      message = message.replace new RegExp(AUTO_LINKIFY_PLACEHOLDER, 'g'), (match, i) ->
        placeholderBlocks.shift()
  
      # replace newlines
      message = message.replace /\n/g, '<br />\n'
  
      # generate quoting clumps
      processedLines = []
      quoteBlock = []
      for idx, line of message.split("\n")
        if line.match /^(&gt;|>)/
          quoteBlock.push line
        else
          processedLines.push th.quoteClump(quoteBlock) if quoteBlock.length
          quoteBlock = []
          processedLines.push line
      processedLines.push th.quoteClump(quoteBlock) if quoteBlock.length
      message = processedLines.join "\n"

    delimit: (number) ->
      # only process real numbers
      return String(number) if isNaN number

      # capture sign and then start working with the absolute value. don't
      # process infinities.
      sign = if number < 0 then '-' else ''
      abs = Math.abs number
      return String(number) if abs is Infinity

      # break out the integer portion and initialize the result to just the
      # decimal (if any)
      integer = Math.floor abs
      result = if abs == integer then '' else String(abs).replace(/^\d+\./, '.')

      # for each comma'd chunk, prepend to the result and remove from integer
      while integer >= 1000
        mod = String(integer).replace(/\d+(\d\d\d)$/, ',$1')
        integer = Math.floor integer / 1000
        result = mod + result

      # integer is now either in [1, 999], or equal to 0 iff number in (-1, 1).
      # prepend it with the sign
      sign + String(integer) + result

    truncateText: (string, options = {}) ->
      max = options.max ? 30
      ellipsis = I18n.t('ellipsis', '...')
      wordSeparator = I18n.t('word_separator', ' ')

      string = (string ? "").replace(/\s+/g, wordSeparator).trim()
      return string if not string or string.length <= max

      truncateAt = 0
      while true
        pos = string.indexOf(wordSeparator, truncateAt + 1)
        break if pos < 0 || pos > max - ellipsis.length
        truncateAt = pos
      truncateAt or= max - ellipsis.length # first word > max, so we cut it

      string.substring(0, truncateAt) + ellipsis
