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

module Api::V1::SisImportError
  include Api::V1::Json

  def sis_import_errors_json(errors)
    errors.map do |e|
      sis_import_error_json(e)
    end
  end

  def sis_import_error_json(error)
    {
      sis_import_id: error.sis_batch_id,
      file: error.file,
      message: error.message,
      row: error.row
    }
  end
end
