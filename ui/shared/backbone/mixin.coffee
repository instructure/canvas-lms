#
# Copyright (C) 2013 - present Instructure, Inc.
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

import {extend, flatten} from 'underscore'

##
# Merges mixins into target, being mindful of certain properties (like
# events) that need to be merged also.

magicMethods = ['attach', 'afterRender', 'initialize']
magicMethodRegex = /// ^ (?:
  __(#{magicMethods.join('|')})__ # cached value with __ prefix/postfix
  | (#{magicMethods.join('|')})   # "raw" uncached method pre-mixin
) $ ///

export default mixin = (target, mixins...) ->
  target = target.prototype if 'function' is typeof target
  for mixin in mixins
    for key, prop of mixin
      # don't blow away old events, merge them
      if key in ['events', 'defaults', 'els']
        # don't extend parent embedded objects, copy them
        parentClassKey = target.constructor?.prototype[key]
        target[key] = extend({}, parentClassKey, target[key], prop)
      # crazy magic multiple inheritence
      else if match = key.match magicMethodRegex
        [alreadyMixedIn, notMixedInYet] = match[1..]
        (target["__#{alreadyMixedIn or notMixedInYet}__"] ||= []).push prop
      else
        target[key] = prop
  for key in ("__#{method}__" for method in magicMethods)
    target[key] = flatten target[key], true if target[key]
  target

