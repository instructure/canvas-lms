/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import ReactDOM from 'react-dom'
import {instanceOf} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import FilePreview from '@canvas/files/react/components/FilePreview'
import File from '@canvas/files/backbone/models/File'
import {asJson, defaultFetchOptions} from '@canvas/util/xhr'

const I18n = useI18nScope('standalone_file_preview')

// showFilePreview repurposes the file preview overlay from the Files
// pages to show a single file in an arbitrary context. First use
// is for canvas files users linked to using the RCE.
export function showFilePreview(file_id, verifier = '') {
  let container = document.getElementById('file_preview_container')
  if (!container) {
    container = document.createElement('div')
    container.id = 'file_preview_container'
    document.body.appendChild(container)
  }
  let url = `/api/v1/files/${file_id}?include[]=enhanced_preview_url`
  if (verifier) {
    url += `&verifier=${verifier}`
  }

  asJson(fetch(url, defaultFetchOptions()))
    .then(file => {
      const backboneFile = new File(file)
      ReactDOM.render(<StandaloneFilePreview preview_file={backboneFile} />, container)
    })
    .catch(err => {
      showFlashAlert({
        message: I18n.t('Failed getting file to preview'),
        err,
      })
    })
}

function StandaloneFilePreview({preview_file}) {
  const [isOpen, setIsOpen] = useState(true)
  const [file, setFile] = useState(preview_file)

  useEffect(() => {
    if (preview_file?.id !== file?.id) {
      setFile(preview_file)
    }
    setIsOpen(!!file)
  }, [file, preview_file])

  return (
    file && (
      <FilePreview
        isOpen={isOpen}
        currentFolder={{
          files: {
            models: [file],
          },
        }}
        query={
          /* the odd value for only_preview is to tease FilePreview into
             not displaying the prev/next arrows */
          {only_preview: 'xyzzy', preview: file.id}
        }
        closePreview={() => setIsOpen(false)}
      />
    )
  )
}
StandaloneFilePreview.propTypes = {
  preview_file: instanceOf(File),
}
