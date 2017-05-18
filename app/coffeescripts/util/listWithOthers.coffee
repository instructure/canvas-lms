#
# Copyright (C) 2012 - present Instructure, Inc.
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

define [
  'i18n!conversations'
  'jquery'
  'str/htmlEscape'
  'jquery.instructure_misc_helpers'
], (I18n, $, h) ->

  (strings, cutoff = 2) ->
    if strings.length > cutoff
      strings = strings[0...cutoff].concat([strings[cutoff...strings.length]])
    $.toSentence(for strOrArray in strings
      if typeof strOrArray is 'string' or strOrArray instanceof h.SafeString
        "<span>#{h(strOrArray)}</span>"
      else
        """
        <span class='others'>
          #{h(I18n.t('other', 'other', count: strOrArray.length))}
          <span>
            <ul>
              #{$.raw (('<li>' + h(str) + '</li>') for str in strOrArray).join('')}
            </ul>
          </span>
        </span>
        """
    )
