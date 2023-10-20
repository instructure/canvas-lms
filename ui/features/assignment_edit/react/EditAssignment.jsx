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

import PropTypes from 'prop-types'
import React, {Suspense} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'

import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import LoadingIndicator from '@canvas/loading-indicator'

const I18n = useI18nScope('assignment')

const FileBrowser = React.lazy(() =>
  import(
    /* webpackChunkName: "[request]" */
    '@canvas/rce/FileBrowser'
  )
)

const attachmentNameStyle = {
  display: 'inline-block',
  overflow: 'hidden',
  textOverflow: 'ellipsis',
  verticalAlign: 'middle',
  whiteSpace: 'nowrap',
  width: '280px',
}

function FileBrowserWrapper(props) {
  return (
    <ErrorBoundary
      errorComponent={
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorCategory="FileBrowser on Create Assignment page"
        />
      }
    >
      <Suspense fallback={<LoadingIndicator />}>
        <FileBrowser {...props} />
      </Suspense>
    </ErrorBoundary>
  )
}

export function AnnotatedDocumentSelector({attachment, defaultUploadFolderId, onSelect, onRemove}) {
  return attachment ? (
    <div>
      <span style={attachmentNameStyle}>{`${attachment.name}`}</span>
      <IconButton
        onClick={() => {
          onRemove(attachment)
        }}
        screenReaderLabel={I18n.t('Remove selected attachment')}
        size="small"
      >
        <IconTrashLine />
      </IconButton>
    </div>
  ) : (
    <FileBrowserWrapper
      defaultUploadFolderId={defaultUploadFolderId}
      selectFile={onSelect}
      allowUpload={true}
      useContextAssets={true}
    />
  )
}

AnnotatedDocumentSelector.propTypes = {
  attachment: PropTypes.shape({
    id: PropTypes.string,
    name: PropTypes.string,
  }),
  defaultUploadFolderId: PropTypes.string,
  onSelect: PropTypes.func,
  onRemove: PropTypes.func,
}

AnnotatedDocumentSelector.defaultProps = {
  defaultUploadFolderId: null,
}
