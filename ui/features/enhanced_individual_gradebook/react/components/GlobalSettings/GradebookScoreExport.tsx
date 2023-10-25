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

import React, {useState, useRef, useEffect} from 'react'
import type {ProgressData} from '@canvas/grading/grading.d'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {ApiCallStatus} from '../../../types'
import {Link} from '@instructure/ui-link'
import {Button} from '@instructure/ui-buttons'
import {IconDownloadLine} from '@instructure/ui-icons'
import DateHelper from '@canvas/datetime/dateHelper'
import {useExportGradebook} from '../../hooks/useExportGradebook'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  lastGeneratedCsvAttachmentUrl: string | null | undefined
  gradebookCsvProgress: ProgressData | null | undefined
  userId?: string | null
  exportGradebookCsvUrl: string | undefined
}
export default function GradebookScoreExport({
  lastGeneratedCsvAttachmentUrl,
  gradebookCsvProgress,
  userId,
  exportGradebookCsvUrl,
}: Props) {
  const [lastGeneratedCsvLink, setLastGeneratedCsvLink] = useState<string | null | undefined>(
    lastGeneratedCsvAttachmentUrl
  )
  const [lastGeneratedCsvLinkText, setLastGeneratedCsvLinkText] = useState<
    string | null | undefined
  >(gradebookCsvProgress?.progress.updated_at)
  const linkRef = useRef<HTMLAnchorElement | null>(null)
  const {exportGradebook, attachmentStatus, attachmentError, attachment} = useExportGradebook()
  useEffect(() => {
    if (attachmentStatus === ApiCallStatus.FAILED) {
      showFlashError('Failed to export gradebook')(attachmentError)
    }
    if (attachmentStatus === ApiCallStatus.COMPLETED && linkRef?.current && attachment?.url) {
      setLastGeneratedCsvLink(attachment.url)
      setLastGeneratedCsvLinkText(attachment.updated_at)
    }
  }, [attachmentStatus, attachmentError, attachment])

  useEffect(() => {
    if (lastGeneratedCsvLink && attachmentStatus === ApiCallStatus.COMPLETED) {
      linkRef.current?.click()
    }
  }, [lastGeneratedCsvLink, attachmentStatus])

  const exportGradebookCsv = async () => {
    if (userId) {
      await exportGradebook(userId, exportGradebookCsvUrl)
    }
  }

  const downloadText = (date: string) => {
    const formattedDate = DateHelper.formatDatetimeForDisplay(date)
    return I18n.t('Download Scores Generated on %{date}', {date: formattedDate})
  }

  return (
    <View as="div" className="pad-box bottom-only">
      <Button
        data-testid="gradebook-export-button"
        color="secondary"
        renderIcon={IconDownloadLine}
        id="gradebook-export"
        interaction={attachmentStatus === ApiCallStatus.PENDING ? 'disabled' : 'enabled'}
        onClick={exportGradebookCsv}
      >
        {I18n.t('Download Current Scores (.csv)')}
      </Button>
      {attachmentStatus !== ApiCallStatus.PENDING &&
        lastGeneratedCsvLink &&
        lastGeneratedCsvLinkText &&
        gradebookCsvProgress && (
          <Link
            elementRef={e => {
              if (e instanceof HTMLAnchorElement) {
                linkRef.current = e
              }
            }}
            href={lastGeneratedCsvLink}
            isWithinText={false}
            margin="0 xx-small"
            data-testid="gradebook-export-link"
          >
            {downloadText(lastGeneratedCsvLinkText)}
          </Link>
        )}
    </View>
  )
}
