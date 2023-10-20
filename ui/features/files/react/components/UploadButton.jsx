/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useCallback, useEffect, useRef, useState} from 'react'
import {bool} from 'prop-types'
import classnames from 'classnames'
import UploadForm, {UploadFormPropTypes} from '@canvas/files/react/components/UploadForm'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'

const I18n = useI18nScope('upload_button')

const UploadButton = function (props) {
  const formRef = useRef(null)
  const [disabled, setDisabled] = useState(UploadQueue.pendingUploads())
  const handleQueueChange = useCallback(upload_queue => {
    setDisabled(!!upload_queue.pendingUploads())
  }, [])

  useEffect(() => {
    UploadQueue.addChangeListener(handleQueueChange)
    return () => UploadQueue.removeChangeListener(handleQueueChange)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  function handleUploadClick() {
    formRef.current?.addFiles()
  }

  const renameFileMessage = nameToUse => {
    return I18n.t(
      'A file named "%{name}" already exists in this folder. Do you want to replace the existing file?',
      {name: nameToUse}
    )
  }

  const lockFileMessage = nameToUse => {
    return I18n.t(
      'A locked file named "%{name}" already exists in this folder. Please enter a new name.',
      {name: nameToUse}
    )
  }

  return (
    <>
      <UploadForm
        allowSkip={true}
        ref={formRef}
        currentFolder={props.currentFolder}
        contextId={props.contextId}
        contextType={props.contextType}
        onRenameFileMessage={renameFileMessage}
        onLockFileMessage={lockFileMessage}
      />
      <button
        type="button"
        className="btn btn-primary btn-upload"
        onClick={handleUploadClick}
        disabled={disabled}
      >
        <i className="icon-upload" aria-hidden={true} />
        &nbsp;
        <span className={classnames({'hidden-phone': props.showingButtons})}>
          {I18n.t('Upload')}
        </span>
      </button>
    </>
  )
}

UploadButton.propTypes = {
  ...UploadFormPropTypes,
  showingButtons: bool,
}

UploadButton.defaultProps = {
  showingButtons: false,
}

export default UploadButton
