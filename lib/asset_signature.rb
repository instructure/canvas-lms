# frozen_string_literal: true

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

module AssetSignature
  DELIMITER = '-'

  def self.generate(asset)
    "#{asset.id}#{DELIMITER}#{generate_hmac(asset.class, asset.id)}"
  end

  def self.find_by_signature(klass, signature)
    id, hmac = signature.split(DELIMITER, 2)
    return nil unless Canvas::Security.verify_hmac_sha1(hmac, "#{klass}#{id}", truncate: 8)
    klass.where(id: id.to_i).first
  end

  private

  def self.generate_hmac(klass, id)
    data = "#{klass}#{id}"
    Canvas::Security.hmac_sha1(data)[0,8]
  end
end
