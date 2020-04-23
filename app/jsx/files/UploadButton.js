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

import I18n from 'i18n!upload_button'
import React, {useCallback, useEffect, useRef, useState} from 'react'
import {bool} from 'prop-types'
import classnames from 'classnames'
import UploadForm, {UploadFormPropTypes} from './UploadForm'
import UploadQueue from 'compiled/react_files/modules/UploadQueue'

const UploadButton = function(props) {
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

  return (
    <>
      <UploadForm
        ref={formRef}
        currentFolder={props.currentFolder}
        contextId={props.contextId}
        contextType={props.contextType}
      />
      <button
        type="button"
        className="btn btn-primary btn-upload"
        onClick={handleUploadClick}
        disabled={disabled}
      >
        <i className="icon-upload" aria-hidden />
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
  showingButtons: bool
}

UploadButton.defaultProps = {
  showingButtons: false
}

export default UploadButton
