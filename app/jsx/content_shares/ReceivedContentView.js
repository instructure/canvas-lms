/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {useState} from 'react'
import I18n from 'i18n!content_share'
import ContentHeading from './ContentHeading'
import ReceivedTable from './ReceivedTable'
import PreviewModal from './PreviewModal'
import {Spinner} from '@instructure/ui-elements'
import useFetchApi from 'jsx/shared/effects/useFetchApi'

export default function ReceivedContentView() {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)
  const [shares, setShares] = useState([])
  const [previewOpen, setPreviewOpen] = useState(false)

  const getSharesUrl = '/api/v1/users/self/content_shares/received'

  useFetchApi({
    success: setShares,
    error: setError,
    loading: setIsLoading,
    path: getSharesUrl
  })

  function onPreview(shareId) {
    setPreviewOpen(true)
  }

  function onImport(shareId) {
    console.log(`onImport action for ${shareId}`)
  }

  if (error) throw new Error(I18n.t('Retrieval of Received Shares failed'))

  return (
    <>
      <ContentHeading
        svgUrl="/images/gift.svg"
        heading={I18n.t('Received Content')}
        description={I18n.t(
          'The list below is content that has been shared with you. You can preview the ' +
            'content, import it into your course, or remove it from the list.'
        )}
      />
      <ReceivedTable shares={shares} onPreview={onPreview} onImport={onImport} />
      {isLoading && <Spinner renderTitle={I18n.t('Loading')} />}
      <PreviewModal open={previewOpen} onDismiss={() => setPreviewOpen(false)} />
    </>
  )
}
