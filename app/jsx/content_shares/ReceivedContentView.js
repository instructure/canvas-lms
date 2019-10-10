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
import {Spinner, Text} from '@instructure/ui-elements'
import useFetchApi from 'jsx/shared/effects/useFetchApi'

const NoContent = () => <Text size="large">{I18n.t('No content has been shared with you.')}</Text>

export default function ReceivedContentView() {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)
  const [shares, setShares] = useState([])
  const [currentPreviewShare, setCurrentPreviewShare] = useState(null)

  const getSharesUrl = '/api/v1/users/self/content_shares/received'

  useFetchApi({
    success: setShares,
    error: setError,
    loading: setIsLoading,
    path: getSharesUrl
  })

  function onPreview(share) {
    setCurrentPreviewShare(share)
  }

  function onImport(shareId) {
    console.log(`onImport action for ${shareId}`)
  }

  function renderBody() {
    const someContent = Array.isArray(shares) && shares.length > 0

    if (isLoading) return <Spinner renderTitle={I18n.t('Loading')} />
    if (someContent)
      return <ReceivedTable shares={shares} onPreview={onPreview} onImport={onImport} />
    return <NoContent />
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
      {renderBody()}
      <PreviewModal
        open={currentPreviewShare !== null}
        share={currentPreviewShare}
        onDismiss={() => setCurrentPreviewShare(null)}
      />
    </>
  )
}
