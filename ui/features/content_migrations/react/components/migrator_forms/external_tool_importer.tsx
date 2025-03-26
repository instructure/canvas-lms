/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useMemo, useRef} from 'react'

import {CommonMigratorControls, ErrorFormMessage} from '@canvas/content-migrations'
import type {onSubmitMigrationFormCallback} from '../types'
import {parseDateToISOString} from '../utils'
import {ImportLabel} from './import_label'
import {ImportInProgressLabel} from './import_in_progress_label'
import {ImportClearLabel} from './import_clear_label'
import {Button} from '@instructure/ui-buttons'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import processMigrationContentItem from '../../../processMigrationContentItem'

const I18n = createI18nScope('content_migrations_redesign')

type ExternalToolImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  isSubmitting: boolean
  value: string
  title: string
}

type handleExternalContentReadyParam = {
  contentItems: {
    url: string
    text: string
  }[]
}

const ExternalToolImporter = ({
  onSubmit,
  onCancel,
  isSubmitting,
  value,
  title,
}: ExternalToolImporterProps) => {
  const [isOpen, setIsOpen] = React.useState(false)
  const [url, setUrl] = React.useState('')
  const [urlError, setUrlError] = React.useState(false)
  const [titleValue, setTitleValue] = React.useState('')
  const courseSelectRef = useRef<HTMLButtonElement | null>(null)

  const {contextType, contextId, selectedToolid} = useMemo(() => {
    const contextInfo = ENV?.context_asset_string?.split('_')
    const contextType = contextInfo[0]
    const contextId = parseInt(contextInfo[1], 10)
    const selectedToolid = value.split('_').pop()
    return {contextType, contextId, selectedToolid}
  }, [value])

  useEffect(() => {
    window.addEventListener('message', processMigrationContentItem)

    return () => {
      window.removeEventListener('message', processMigrationContentItem)
    }
  })

  const handleSubmit: onSubmitMigrationFormCallback = useCallback(
    formData => {
      formData.settings.file_url = url
      setUrlError(!url)
      if (!url) {
        courseSelectRef.current?.focus()
        return
      }
      onSubmit(formData)
    },
    [url, onSubmit],
  )

  const handleExternalContentReady = (data: handleExternalContentReadyParam) => {
    if (!data.contentItems || data.contentItems.length === 0) {
      return
    }
    const item = data.contentItems[0]
    setUrl(item.url)
    setTitleValue(item.text)
  }

  const openExternalToolModal = () => setIsOpen(true)
  const getFindCourseButtonAriaLabel = () => {
    if (urlError) {
      return `${I18n.t('File upload or URL is required')} ${I18n.t('Find a Course')}`
    }
    return I18n.t('Find a Course')
  }

  return (
    <>
      <Flex>
        <Button
          onClick={openExternalToolModal}
          elementRef={ref => (courseSelectRef.current = ref as HTMLButtonElement)}
          data-testid="find-course-button"
          aria-label={getFindCourseButtonAriaLabel()}
        >
          {I18n.t('Find a Course')}
        </Button>
        {!!titleValue && (
          <View as="div" margin="small">
            {titleValue}
          </View>
        )}
      </Flex>
      {urlError && (
        <View as="div" margin="small 0">
          <ErrorFormMessage>{I18n.t('File upload or URL is required')}</ErrorFormMessage>
        </View>
      )}
      <ExternalToolModalLauncher
        tool={{
          definition_id: selectedToolid!,
        }}
        title={title}
        isOpen={isOpen}
        onRequestClose={() => setIsOpen(false)}
        contextType={contextType}
        contextId={contextId}
        launchType={'migration_selection'}
        onExternalContentReady={handleExternalContentReady}
        resourceSelection
      />

      <CommonMigratorControls
        fileUploadProgress={null}
        isSubmitting={isSubmitting}
        canAdjustDates={false}
        canSelectContent={true}
        canOverwriteAssessmentContent={false}
        onSubmit={handleSubmit}
        onCancel={onCancel}
        newStartDate={parseDateToISOString(ENV.OLD_START_DATE)}
        newEndDate={parseDateToISOString(ENV.OLD_END_DATE)}
        SubmitLabel={ImportLabel}
        SubmittingLabel={ImportInProgressLabel}
        CancelLabel={ImportClearLabel}
      />
    </>
  )
}

export default ExternalToolImporter
