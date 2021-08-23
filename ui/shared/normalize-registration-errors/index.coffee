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

import User from '@canvas/users/backbone/models/User.coffee'
import Pseudonym from '@canvas/pseudonyms/backbone/models/Pseudonym.coffee'
import ObserverPairingCode from './backbone/models/ObserverPairingCodeModel'
import flatten from 'obj-flatten'

# normalize errors we get from POST /user (user creation API)
export default registrationErrors = (errors, passwordPolicy = ENV.PASSWORD_POLICY) ->
  flatten
    user: User::normalizeErrors(errors.user)
    pseudonym: Pseudonym::normalizeErrors(errors.pseudonym, passwordPolicy)
    observee: Pseudonym::normalizeErrors(errors.observee, passwordPolicy)
    pairing_code: ObserverPairingCode::normalizeErrors(errors.pairing_code)
  , arrays: false
