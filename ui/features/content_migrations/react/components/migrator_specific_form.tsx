/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import CourseCopyImporter from './migrator_forms/course_copy'
import CanvasCartridgeImporter from './migrator_forms/canvas_cartridge'

type MigratorSpecificFormProps = {
  migrator: string
  setSourceCourse: (sourceCourseId: string) => void
  onSelectPreAttachmentFile: (preAttachmentFile: File | null) => void
}

export const MigratorSpecificForm = ({
  migrator,
  setSourceCourse,
  onSelectPreAttachmentFile,
}: MigratorSpecificFormProps) => {
  if (migrator === 'course_copy_importer') {
    return <CourseCopyImporter setSourceCourse={setSourceCourse} />
  } else if (migrator === 'canvas_cartridge_importer') {
    return <CanvasCartridgeImporter onSelectPreAttachmentFile={onSelectPreAttachmentFile} />
  }
  return null
}

export default MigratorSpecificForm
