#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Schemas::Lti
  class PublicJwk < Schemas::Base
    SCHEMA = {
      'type' => 'object',
      'required' => %w[kty e n kid alg use].freeze,
      'properties' => {
        'kty' => {
          'type' => 'string',
          'const' => Lti::RSAKeyPair::KTY
        }.freeze,
        'alg' => {
          'type' => 'string',
          'const' => Lti::RSAKeyPair::ALG
        }.freeze,
        'e' => {
          'type' => 'string'
        }.freeze,
        'n' => {
          'type' => 'string'
        }.freeze,
        'kid' => {
          'type' => 'string'
        }.freeze,
        'use' => {
          'type' => 'string'
        }.freeze
      }.freeze
    }.freeze

    private

    def schema
      SCHEMA
    end
  end
end