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

import React, {useEffect, useState, lazy} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import CanvasLazyTray from '@canvas/trays/react/LazyTray'
import ContentHeading from './ContentHeading'
import ReceivedTable from './ReceivedTable'
import PreviewModal from './PreviewModal'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import useFetchApi from '@canvas/use-fetch-api-hook'
import doFetchApi from '@canvas/do-fetch-api-effect'
import Paginator from '@canvas/instui-bindings/react/Paginator'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('content_share')

const CourseImportPanel = lazy(() => import('./CourseImportPanel'))
const NoContent = () => <Text size="large">{I18n.t('No content has been shared with you.')}</Text>

export default function ReceivedContentView() {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)
  const [shares, setShares] = useState([])
  const [responseMeta, setResponseMeta] = useState({})
  const [currentPage, setCurrentPage] = useState(1)
  const [currentContentShare, setCurrentContentShare] = useState(null)
  const [whichModalOpen, setWhichModalOpen] = useState(null)

  const sharesUrl = '/api/v1/users/self/content_shares'

  useFetchApi({
    success: setShares,
    meta: setResponseMeta,
    error: setError,
    loading: setIsLoading,
    path: `${sharesUrl}/received`,
    params: {page: currentPage},
  })

  useEffect(() => {
    if (!isLoading) {
      const message = I18n.t(
        {
          one: '1 shared item loaded.',
          other: '%{count} shared items loaded.',
        },
        {count: shares.length}
      )
      showFlashAlert({message, srOnly: true, type: 'info'})
    }
  }, [shares, isLoading])

  function removeShareFromList(doomedShare) {
    setShares(shares.filter(share => share.id !== doomedShare.id))
  }

  // Handle an update to a read state from the displayed table
  function onUpdate(share_id, updateParms) {
    doFetchApi({
      method: 'PUT',
      path: `${sharesUrl}/${share_id}`,
      body: updateParms,
    })
      .then(r => {
        const {id, read_state} = r.json
        setShares(shares.map(share => (share.id === id ? {...share, read_state} : share)))
      })
      .catch(setError)
  }

  function markRead(share) {
    onUpdate(share.id, {read_state: 'read'})
  }

  function onPreview(share) {
    setCurrentContentShare(share)
    setWhichModalOpen('preview')
    markRead(share)
  }

  function onImport(share) {
    setCurrentContentShare(share)
    setWhichModalOpen('import')
  }

  function onRemove(share) {
    // eslint-disable-next-line no-alert
    const shouldRemove = window.confirm(I18n.t('Are you sure you want to remove this item?'))
    if (shouldRemove) {
      doFetchApi({path: `${sharesUrl}/${share.id}`, method: 'DELETE'})
        .then(() => removeShareFromList(share))
        .catch(err =>
          showFlashAlert({message: I18n.t('There was an error removing the item'), err})
        )
    }
  }

  function closeModal() {
    setWhichModalOpen(null)
  }

  function renderBody() {
    const someContent = Array.isArray(shares) && shares.length > 0

    if (isLoading) return <Spinner renderTitle={I18n.t('Loading')} />
    if (someContent)
      return (
        <ReceivedTable
          shares={shares}
          onPreview={onPreview}
          onImport={onImport}
          onRemove={onRemove}
          onUpdate={onUpdate}
        />
      )
    return <NoContent />
  }

  function renderPagination() {
    if (responseMeta.link) {
      const last = parseInt(responseMeta.link.last.page, 10)
      if (!Number.isNaN(last)) {
        return (
          <Paginator
            loadPage={setCurrentPage}
            page={currentPage}
            pageCount={last}
            margin="small 0 0 0"
          />
        )
      }
    }
  }

  if (error) throw new Error('Retrieval of Received Shares failed')

  return (
    <>
      <ScreenReaderContent>
        <Heading level="h1">{I18n.t('Shared Content')}</Heading>
      </ScreenReaderContent>
      <ContentHeading
        svgUrl="/images/gift.svg"
        heading={I18n.t('Received Content')}
        description={I18n.t(
          'The list below is content that has been shared with you. You can preview the ' +
            'content, import it into your course, or remove it from the list.'
        )}
      />
      {renderBody()}
      {renderPagination()}
      <PreviewModal
        open={whichModalOpen === 'preview'}
        share={currentContentShare}
        onDismiss={closeModal}
      />
      <CanvasLazyTray
        label={I18n.t('Import...')}
        open={whichModalOpen === 'import'}
        placement="end"
        padding="medium"
        onDismiss={closeModal}
      >
        <CourseImportPanel
          contentShare={currentContentShare}
          onClose={closeModal}
          onImport={markRead}
        />
      </CanvasLazyTray>
    </>
  )
}
