# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
require 'audits'

module Auditors
  # TODO: this module is currently being extracted to the
  # audits engine.  This module shim is remaining in place
  # to ease the transition and prevent surprise breakages. Once all callsites are patched,
  # remove this shim entirely.
  def self.method_missing(message, *args, &block)
    Rails.logger.warn("[DEPRECATION] The Auditors module is being relocated, change callsites to use the 'Audits' module")
    Audits.send(message, *args, &block)
  end
end
