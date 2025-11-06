/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState, useEffect, useCallback} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tray} from '@instructure/ui-tray'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Modal} from '@instructure/ui-modal'
import {Spinner} from '@instructure/ui-spinner'
import {dateString} from '@instructure/moment-utils'

interface SyllabusVersion {
  version: number
  created_at: string
  syllabus_body: string
  updated_at?: string
}

interface SyllabusRevisionsTrayProps {
  courseId: string
  open: boolean
  onDismiss: () => void
}

export default function SyllabusRevisionsTray({
  courseId,
  open,
  onDismiss,
}: SyllabusRevisionsTrayProps) {
  const I18n = useI18nScope('syllabus_revisions')
  const [versions, setVersions] = useState<SyllabusVersion[]>([])
  const [loading, setLoading] = useState(false)
  const [selectedVersion, setSelectedVersion] = useState<SyllabusVersion | null>(null)
  const [confirmModalOpen, setConfirmModalOpen] = useState(false)
  const [versionToRestore, setVersionToRestore] = useState<SyllabusVersion | null>(null)
  const [restoring, setRestoring] = useState(false)
  const [currentSyllabusBody, setCurrentSyllabusBody] = useState<string | null>(null)

  const fetchVersions = useCallback(async () => {
    setLoading(true)
    try {
      const {json} = await doFetchApi({
        path: `/api/v1/courses/${courseId}`,
        params: {include: ['syllabus_versions']},
      })
      const data = json as {syllabus_versions?: SyllabusVersion[]}
      setVersions(data.syllabus_versions || [])
      if (data.syllabus_versions && data.syllabus_versions.length > 0) {
        setSelectedVersion(data.syllabus_versions[0])
        const syllabusElement = document.getElementById('course_syllabus')
        if (syllabusElement) {
          setCurrentSyllabusBody(syllabusElement.innerHTML)
        }
      }
    } catch (error) {
      showFlashError(I18n.t('Failed to load syllabus versions'))(error as Error)
    } finally {
      setLoading(false)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId])

  useEffect(() => {
    if (open) {
      fetchVersions()
    } else if (currentSyllabusBody) {
      const syllabusElement = document.getElementById('course_syllabus')
      if (syllabusElement && syllabusElement.innerHTML !== currentSyllabusBody) {
        syllabusElement.innerHTML = currentSyllabusBody
      }
    }
  }, [open, fetchVersions, currentSyllabusBody])

  const formatDateTime = (dateStr: string) => {
    const date = new Date(dateStr)
    const formatted = dateString(date, {format: 'full'})
    const parts = formatted.split(' ')
    if (parts.length >= 4) {
      const datePart = parts.slice(0, 3).join(' ')
      const timePart = parts.slice(3).join(' ')
      return `${datePart} at ${timePart}`
    }
    return formatted
  }

  const isSameAsCurrentVersion = (version: SyllabusVersion) => {
    return version.syllabus_body === versions[0]?.syllabus_body
  }

  const handleVersionClick = (version: SyllabusVersion) => {
    const syllabusElement = document.getElementById('course_syllabus')
    let shouldUpdateDOM = false

    if (syllabusElement && version.syllabus_body) {
      const normalizedCurrent = syllabusElement.innerHTML.trim()
      const normalizedNew = version.syllabus_body.trim()
      shouldUpdateDOM = normalizedCurrent !== normalizedNew

      if (shouldUpdateDOM) {
        syllabusElement.innerHTML = version.syllabus_body
      }
    }

    setSelectedVersion(version)
  }

  const handleRestore = (version: SyllabusVersion) => {
    setVersionToRestore(version)
    setConfirmModalOpen(true)
  }

  const handleConfirmRestore = async () => {
    if (versionToRestore) {
      setRestoring(true)
      try {
        await doFetchApi({
          path: `/api/v1/courses/${courseId}/restore/${versionToRestore.version}`,
          method: 'POST',
        })
        showFlashAlert({
          message: I18n.t('Revision successfully restored'),
          type: 'success',
        })
        await fetchVersions()
        setConfirmModalOpen(false)
        setVersionToRestore(null)
      } catch (error) {
        showFlashError(I18n.t('Failed to restore version'))(error as Error)
      } finally {
        setRestoring(false)
      }
    }
  }

  const handleCancelRestore = () => {
    setConfirmModalOpen(false)
    setVersionToRestore(null)
  }

  const handleTrayDismiss = () => {
    const syllabusElement = document.getElementById('course_syllabus')
    if (
      syllabusElement &&
      currentSyllabusBody &&
      syllabusElement.innerHTML !== currentSyllabusBody
    ) {
      syllabusElement.innerHTML = currentSyllabusBody
    }
    onDismiss()
  }

  const revisionText = (version: SyllabusVersion, index: number) => {
    const isCurrent = index === 0
    if (isCurrent) {
      return I18n.t('Latest revision')
    } else if (isSameAsCurrentVersion(version)) {
      return I18n.t('Same as latest revision')
    }
  }

  return (
    <>
      <Tray
        data-testid="syllabus-revisions-tray"
        label={I18n.t('Syllabus revision history')}
        onDismiss={handleTrayDismiss}
        open={open}
        placement="end"
        size="small"
        shouldContainFocus
        shouldReturnFocus
        shouldCloseOnDocumentClick={false}
      >
        <View as="div" padding="medium">
          <Flex margin="0 0 medium 0">
            <Flex.Item>
              <CloseButton
                placement="end"
                offset="small"
                screenReaderLabel={I18n.t('Close')}
                onClick={handleTrayDismiss}
                data-testid="close-tray-button"
              />
            </Flex.Item>
            <Flex.Item shouldGrow shouldShrink>
              <Heading as="h2" level="h3">
                {I18n.t('Revision History')}
              </Heading>
            </Flex.Item>
          </Flex>

          <View as="div" margin="medium 0 0 0">
            {loading ? (
              <View as="div" textAlign="center" padding="medium">
                <Spinner renderTitle={I18n.t('Loading')} size="medium" />
              </View>
            ) : (
              <List isUnstyled margin="0" itemSpacing="xxx-small">
                {versions.map((version, index) => {
                  const isSelected = selectedVersion?.version === version.version
                  const isCurrent = index === 0
                  const isSame = isSameAsCurrentVersion(version)

                  return (
                    <List.Item key={version.version}>
                      <View
                        as="div"
                        padding="x-small small"
                        borderWidth="0 0 0 small"
                        borderColor={isSelected ? 'licorice' : 'transparent'}
                        background="primary"
                        cursor="pointer"
                        onClick={() => handleVersionClick(version)}
                        data-testid={isCurrent ? 'current-version' : `version-${version.version}`}
                        themeOverride={isSelected ? {backgroundPrimary: '#E0EBF5'} : undefined}
                      >
                        <View as="div" margin="0 0 xx-small 0">
                          <Text weight="bold" lineHeight="condensed">
                            {formatDateTime(version.created_at)}
                          </Text>
                        </View>
                        {revisionText(version, index) && (
                          <View as="div">
                            <Text lineHeight="condensed">{revisionText(version, index)}</Text>
                          </View>
                        )}
                        {isSelected && !isCurrent && !isSame && (
                          <Button
                            size="small"
                            onClick={e => {
                              e.stopPropagation()
                              handleRestore(version)
                            }}
                            data-testid={`restore-version-${version.version}`}
                          >
                            {I18n.t('Restore this version')}
                          </Button>
                        )}
                      </View>
                    </List.Item>
                  )
                })}
              </List>
            )}

            {!loading && versions.length === 0 && (
              <Text color="secondary">{I18n.t('No previous versions available')}</Text>
            )}
          </View>
        </View>
      </Tray>

      <Modal
        open={confirmModalOpen}
        onDismiss={handleCancelRestore}
        size="small"
        label={I18n.t('Confirm restore')}
      >
        <Modal.Header>
          <Heading>{I18n.t('Confirm restore')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Text>
            {versionToRestore && I18n.t('Are you sure you want to restore this revision?')}
          </Text>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={handleCancelRestore} margin="0 x-small 0 0" disabled={restoring}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            onClick={handleConfirmRestore}
            data-testid="confirm-restore"
            disabled={restoring}
          >
            {restoring ? I18n.t('Restoring...') : I18n.t('Restore')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
