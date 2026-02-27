/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import axios from "axios";

export function createOnTranscriptEdit(attachment_id: string, jwt: string) {
  return (formData: FormData): Promise<void> =>
    new Promise((resolve, reject) =>
      axios({
        method: "POST",
        url: `/media_attachments/${attachment_id}/media_tracks`,
        headers: {
          Authorization: `Bearer ${jwt}`,
        },
        data: formData,
      })
        .then(() => resolve())
        .catch(() => reject())
    )
}

export function onConfirmEditChanges(): void {
  window.location.reload()
}
