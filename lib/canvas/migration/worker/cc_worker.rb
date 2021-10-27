# frozen_string_literal: true

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
#

# This alias is to please the ContentMigration code, which makes the
# assumption that all content migration workers must live within the
# namespace "Canvas::Migration::Worker::...".  Since the CCWorker
# actually lives in another part of the codebase, allowing this
# alias to exist permits "const_get" to succeed in loading the correct worker.
Canvas::Migration::Worker::CCWorker = CC::Importer::CCWorker
