#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'i18n!instructure'
], (I18n) ->
  # converts bytes into a nice representation with unit. e.g. 13661855 -> 13.7 MB, 825399 -> 825 KB, 1396 -> 1 KB
  friendlyBytes = (value) ->
    bytes = parseInt(value, 10)
    if bytes.toString() is 'NaN'
      return '--'
    units = ['byte', 'bytes', 'KB', 'MB', 'GB', 'TB']

    if bytes is 0
      resInt = resValue = 0
    else
      resInt = Math.floor(Math.log(bytes) / Math.log(1000)) # base 10 (rather than 1024) matches Mac OS X
      resValue = (bytes / Math.pow(1000, Math.floor(resInt))).toFixed(if resInt < 2 then 0 else 1) # no decimals for anything smaller than 1 MB
      resInt = -1 if bytes is 1 # 1 byte special case

    I18n.n(resValue) + ' ' + units[resInt + 1]
