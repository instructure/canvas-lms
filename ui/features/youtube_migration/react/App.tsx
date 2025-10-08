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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton, CondensedButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Table} from '@instructure/ui-table'
import EmptyDesert from '@canvas/images/react/EmptyDesert'
import celebratePandaUrl from '@canvas/images/CelebratePanda.svg'
import {
  QueryClient,
  type QueryFunctionContext,
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query'
import {YoutubeEmbed, YoutubeScanResource, YoutubeScanResultReport} from '../../../api'
import doFetchApi from '@canvas/do-fetch-api-effect'
import GenericErrorPage from '@canvas/generic-error-page/react'
import ErrorShip from '@canvas/images/ErrorShip.svg'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Link} from '@instructure/ui-link'
import {
  IconAssignmentLine,
  IconDiscussionLine,
  IconDocumentLine,
  IconCheckSolid,
} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {type CanvasProgress} from '@canvas/progress/ProgressHelpers'
import Paginator from '@canvas/instui-bindings/react/Paginator'
import {Pill} from '@instructure/ui-pill'

export interface AppProps {
  courseId: string
}

enum YoutubeScanWorkflowState {
  Completed = 'completed',
  Failed = 'failed',
  Queued = 'queued',
  Running = 'running',
  WaitingForExternalTool = 'waiting_for_external_tool',
}

const I18n = createI18nScope('youtube_migration')

const NoScanFoundView: React.FC<{
  handleCourseScan?: () => void
  isRequestLoading?: boolean
}> = ({handleCourseScan, isRequestLoading}) => {
  return (
    <Wrapper handleCourseScan={handleCourseScan} scanButtonDisabled={isRequestLoading}>
      <Flex justifyItems="center" margin="0 0 large">
        <Flex.Item>
          <EmptyDesert />
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center" margin="0 0 large">
        <Flex.Item>
          <Text>{I18n.t('You haven’t scanned your course yet')}</Text>
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center" margin="0 0 large">
        <Flex.Item>
          <CondensedButton disabled={isRequestLoading} onClick={handleCourseScan}>
            {I18n.t('Scan Course')}
          </CondensedButton>
        </Flex.Item>
      </Flex>
    </Wrapper>
  )
}

const LoadingView = () => {
  return (
    <Wrapper scanButtonDisabled={true}>
      <Flex justifyItems="center" padding="large">
        <Flex.Item textAlign="center">
          <Spinner renderTitle={() => I18n.t('Course scan result is loading')} size="large" />
        </Flex.Item>
      </Flex>
    </Wrapper>
  )
}

const ScanningInProgressView = () => {
  return (
    <Wrapper scanButtonDisabled={true}>
      <Flex justifyItems="center" margin="xx-large 0 small 0">
        <Flex.Item>
          <Spinner renderTitle={() => I18n.t('Scanning in progress')} size="small" />
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center">
        <Flex.Item>
          <Text size="large">{I18n.t('Hang tight!')}</Text>
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center">
        <Flex.Item>
          <View as="div" textAlign="center" maxWidth="24rem">
            <Text size="small">
              {I18n.t(
                'Scanning might take a few seconds or up to several minutes, depending on how much content your course contains.',
              )}
            </Text>
          </View>
        </Flex.Item>
      </Flex>
    </Wrapper>
  )
}

const LastScanFailedResultView: React.FC<{
  handleCourseScan?: () => void
  isRequestLoading?: boolean
}> = ({handleCourseScan, isRequestLoading}) => {
  return (
    <Wrapper handleCourseScan={handleCourseScan} scanButtonDisabled={isRequestLoading}>
      <GenericErrorPage
        imageUrl={ErrorShip}
        errorSubject={I18n.t('Last YouTube content scan failed.')}
        errorCategory={I18n.t('YouTube Migration Error Page.')}
        errorMessage={I18n.t('Try to scan again.')}
      />
    </Wrapper>
  )
}

const LastScanEmptyResultView: React.FC<{
  handleCourseScan?: () => void
  isRequestLoading?: boolean
}> = ({handleCourseScan, isRequestLoading}) => {
  return (
    <Wrapper handleCourseScan={handleCourseScan} scanButtonDisabled={isRequestLoading}>
      <Flex justifyItems="center" margin="large 0 medium 0">
        <Flex.Item>
          <Img
            src={celebratePandaUrl}
            alt={I18n.t('Panda celebrate that there is no youtube embedding found.')}
          />
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center">
        <Flex.Item>
          <Text size="large">{I18n.t('No YouTube content detected with ads')}</Text>
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center">
        <Flex.Item>
          <View as="div" textAlign="center" maxWidth="24rem">
            <Text size="small">
              {I18n.t(
                'If you changed anything since the last scan you need to scan again for the updated list',
              )}
            </Text>
          </View>
        </Flex.Item>
      </Flex>
      <Flex justifyItems="center" margin="x-large 0 0 0">
        <Flex.Item>
          <CondensedButton disabled={isRequestLoading} onClick={handleCourseScan}>
            {I18n.t('Scan Again')}
          </CondensedButton>
        </Flex.Item>
      </Flex>
    </Wrapper>
  )
}

// TODO add all the type
const getResultType = (type: string) => {
  const margin = '0 x-small 0 0'
  switch (type) {
    case 'WikiPage':
      return (
        <Flex>
          <Flex.Item margin={margin}>
            <IconDocumentLine />
          </Flex.Item>
          <Flex.Item>
            <Text>{I18n.t('Page')}</Text>
          </Flex.Item>
        </Flex>
      )
    case 'Assignment':
      return (
        <Flex>
          <Flex.Item margin={margin}>
            <IconAssignmentLine />
          </Flex.Item>
          <Flex.Item>
            <Text>{I18n.t('Assignment')}</Text>
          </Flex.Item>
        </Flex>
      )
    case 'DiscussionTopic':
      return (
        <Flex>
          <Flex.Item margin={margin}>
            <IconDiscussionLine />
          </Flex.Item>
          <Flex.Item>
            <Text>{I18n.t('Discussion')}</Text>
          </Flex.Item>
        </Flex>
      )
    default:
      return (
        <Flex>
          <Flex.Item>
            <Text>{I18n.t('Resource')}</Text>
          </Flex.Item>
        </Flex>
      )
  }
}

const createYoutubeConvertMutation = async ({
  courseId,
  scanId,
  embed,
  embedIndex,
}: {
  courseId: string
  scanId: number
  embed: YoutubeEmbed
  embedIndex: number
}): Promise<{
  progress: CanvasProgress
  embedIndex: number
}> => {
  const {json, response} = await doFetchApi<CanvasProgress>({
    path: `/api/v1/courses/${courseId}/youtube_migration/convert`,
    method: 'POST',
    body: {embed, scan_id: scanId},
  })

  if (!response.ok || json === undefined) {
    throw new Error(I18n.t('Failed to convert'))
  }

  return {progress: json, embedIndex}
}

enum ConvertStatus {
  Converted = 'converted',
  Converting = 'converting',
  Failed = 'failed',
}

const EmbedsModal: React.FC<{
  youtubeEmbeds: Array<YoutubeEmbed>
  resourceTitle: string
  showModal: boolean
  closeModalFunction: () => void
  courseId: string
  scanId: number
  handleOnClose: () => void
  resourceType: string
  resourceId: number
}> = ({
  youtubeEmbeds,
  resourceTitle,
  showModal,
  closeModalFunction,
  courseId,
  scanId,
  handleOnClose,
  resourceType,
  resourceId,
}) => {
  const isConvertHappened = useRef(false)
  const [youtubeEmbedsState, setYoutubeEmbedsState] =
    useState<Array<YoutubeEmbed & {convertStatus?: ConvertStatus}>>(youtubeEmbeds)
  const activePolls = useRef<Map<number, number>>(new Map())
  const [isCheckingExistingConversions, setIsCheckingExistingConversions] = useState(false)

  useEffect(() => {
    setYoutubeEmbedsState(youtubeEmbeds)
  }, [setYoutubeEmbedsState, youtubeEmbeds])

  useEffect(() => {
    const polls = activePolls.current
    return () => {
      polls.forEach(timeoutId => clearTimeout(timeoutId))
      polls.clear()
    }
  }, [])

  const handleEmbedConvertStatus = useCallback(
    (embedIndex: number, convertStatus: ConvertStatus) => {
      if (convertStatus === ConvertStatus.Converted || convertStatus === ConvertStatus.Failed) {
        const timeoutId = activePolls.current.get(embedIndex)
        if (timeoutId) {
          clearTimeout(timeoutId)
          activePolls.current.delete(embedIndex)
        }
      }

      setYoutubeEmbedsState(prevEmbeds =>
        prevEmbeds.map((embed, index) =>
          index === embedIndex ? {...embed, convertStatus} : embed,
        ),
      )
    },
    [],
  )

  const startProgressPolling = useCallback(
    (progressId: string, embedIndex: number) => {
      const existingTimeoutId = activePolls.current.get(embedIndex)
      if (existingTimeoutId) {
        clearTimeout(existingTimeoutId)
      }

      const pollProgress = async () => {
        try {
          const {json} = await doFetchApi<CanvasProgress>({
            path: `/api/v1/progress/${progressId}`,
          })

          const progress = json!

          if (progress.workflow_state === 'completed') {
            if (progress.results && progress.results.success === true) {
              handleEmbedConvertStatus(embedIndex, ConvertStatus.Converted)
            } else {
              handleEmbedConvertStatus(embedIndex, ConvertStatus.Failed)
              const errorMessage =
                progress.results?.error || I18n.t('Conversion failed with unknown error')
              showFlashError(errorMessage)()
            }
          } else if (progress.workflow_state === 'failed') {
            handleEmbedConvertStatus(embedIndex, ConvertStatus.Failed)
            showFlashError(progress.results?.error || I18n.t('Conversion failed'))()
          } else if (
            progress.workflow_state === 'queued' ||
            progress.workflow_state === 'running' ||
            progress.workflow_state === 'waiting_for_external_tool'
          ) {
            // Continue polling
            const timeoutId = window.setTimeout(pollProgress, 2000)
            activePolls.current.set(embedIndex, timeoutId)
          }
        } catch (_error) {
          handleEmbedConvertStatus(embedIndex, ConvertStatus.Failed)
          showFlashError(I18n.t('Failed to check conversion progress'))()
        }
      }

      pollProgress()
    },
    [handleEmbedConvertStatus],
  )

  const mutation = useMutation({
    mutationKey: ['youtubeMigration', 'createConvert', courseId],
    mutationFn: createYoutubeConvertMutation,
    onSuccess: ({progress, embedIndex}) => {
      convertHappened()
      handleEmbedConvertStatus(embedIndex, ConvertStatus.Converting)
      startProgressPolling(progress.id, embedIndex)
    },
    onError: (_error, variables) => {
      if (variables?.embedIndex !== undefined) {
        handleEmbedConvertStatus(variables.embedIndex, ConvertStatus.Failed)
      }
      showFlashError(
        I18n.t(
          'Something went wrong during convert the YouTube video. Reload the page and try again.',
        ),
      )()
    },
  })

  const handleEmbedConvert = (courseId: string, embed: YoutubeEmbed, index: number) => {
    if (embed.src.includes('/embed/videoseries')) {
      showFlashError(
        I18n.t(
          "This content was added as a YouTube playlist, which can't be converted. Please resolve it manually.",
        ),
      )()
      return
    }

    handleEmbedConvertStatus(index, ConvertStatus.Converting)
    mutation.mutate({courseId, scanId, embed, embedIndex: index})
  }

  const handleModalClose = () => {
    // Stop all active polling when modal closes
    const polls = activePolls.current
    polls.forEach(timeoutId => clearTimeout(timeoutId))
    polls.clear()

    // Reset all convert button states to allow retry when modal reopens
    setYoutubeEmbedsState(prevEmbeds =>
      prevEmbeds.map(embed => ({
        ...embed,
        convertStatus: undefined,
      })),
    )

    if (isConvertHappened.current) {
      handleOnClose()
    }
    isConvertHappened.current = false
  }

  const convertHappened = () => {
    isConvertHappened.current = true
  }

  const checkExistingConversions = useCallback(async () => {
    setIsCheckingExistingConversions(true)
    try {
      const params = new URLSearchParams({
        resource_type: resourceType,
        resource_id: resourceId.toString(),
      })
      const {json} = await doFetchApi<{
        conversions: Array<{
          id: string
          workflow_state: string
          original_embed: YoutubeEmbed
        }>
      }>({
        path: `/api/v1/courses/${courseId}/youtube_migration/conversion_status?${params.toString()}`,
      })

      if (json && json.conversions) {
        json.conversions.forEach(conversion => {
          const originalEmbed = conversion.original_embed
          if (originalEmbed) {
            const embedIndex = youtubeEmbeds.findIndex(
              embed => embed.src === originalEmbed.src && embed.path === originalEmbed.path,
            )
            if (embedIndex !== -1) {
              handleEmbedConvertStatus(embedIndex, ConvertStatus.Converting)
              startProgressPolling(conversion.id, embedIndex)
            }
          }
        })
      }
    } catch (_error) {
      showFlashError(I18n.t('Failed to check existing conversions'))()
    } finally {
      setIsCheckingExistingConversions(false)
    }
  }, [
    courseId,
    resourceType,
    resourceId,
    youtubeEmbeds,
    handleEmbedConvertStatus,
    startProgressPolling,
  ])

  useEffect(() => {
    if (showModal && resourceType && resourceId) {
      checkExistingConversions()
    }
  }, [showModal, resourceType, resourceId, checkExistingConversions])

  const getConvertButtonText = (convertStatus?: ConvertStatus): string => {
    if (convertStatus === ConvertStatus.Converted) {
      return I18n.t('Converted')
    } else if (convertStatus === ConvertStatus.Converting) {
      return I18n.t('Converting...')
    } else if (convertStatus === ConvertStatus.Failed) {
      return I18n.t('Failed - Retry')
    }
    return I18n.t('Convert')
  }

  return (
    <Modal
      open={showModal}
      onDismiss={closeModalFunction}
      size="auto"
      label={I18n.t('YouTube Embeds Review')}
      shouldCloseOnDocumentClick
      onClose={handleModalClose}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={closeModalFunction}
          screenReaderLabel={I18n.t('Close')}
        />
        {resourceTitle && <Heading>{resourceTitle}</Heading>}
      </Modal.Header>
      <Modal.Body>
        {youtubeEmbedsState.map((embed, index) => {
          const isAlreadyConverted = embed.converted === true
          const effectiveConvertStatus = isAlreadyConverted
            ? ConvertStatus.Converted
            : embed.convertStatus

          return (
            <View key={index} as="div" margin="medium 0 0 0" minWidth="35rem">
              <Flex justifyItems="center" direction="column">
                <Flex.Item>
                  <Flex justifyItems="center">
                    <Flex.Item>
                      <iframe
                        src={embed.src}
                        title={I18n.t('YouTube Embed')}
                        width="500"
                        height="315"
                        style={{border: 'none'}}
                      />
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
                <Flex.Item margin="medium 0 0 0" padding="x-small">
                  <Button
                    color="primary"
                    display="block"
                    onClick={() => handleEmbedConvert(courseId, embed, index)}
                    disabled={
                      isCheckingExistingConversions ||
                      isAlreadyConverted ||
                      effectiveConvertStatus === ConvertStatus.Converted ||
                      effectiveConvertStatus === ConvertStatus.Converting
                    }
                  >
                    {(effectiveConvertStatus === ConvertStatus.Converting ||
                      (isCheckingExistingConversions && !effectiveConvertStatus)) && (
                      <Spinner
                        renderTitle={() => I18n.t('Converting')}
                        size="x-small"
                        margin="0 small 0 0"
                      />
                    )}
                    {isAlreadyConverted
                      ? I18n.t('Converted')
                      : isCheckingExistingConversions && !effectiveConvertStatus
                        ? I18n.t('Checking...')
                        : getConvertButtonText(effectiveConvertStatus)}
                  </Button>
                </Flex.Item>
              </Flex>
              {index < youtubeEmbeds.length - 1 && <View as="hr" />}
            </View>
          )
        })}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={closeModalFunction} margin="0 x-small 0 0">
          {I18n.t('Close')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

const LastScanResultView: React.FC<{
  resources: Array<YoutubeScanResource>
  totalCount: number
  totalConverted?: number
  courseId: string
  scanId: number
  handleCourseScan: () => void
  isRequestLoading: boolean
  handleCourseScanReload: () => void
  currentPage: number
  perPage: number
  totalPages: number
  onPageChange: (page: number) => void
}> = ({
  resources,
  handleCourseScan,
  isRequestLoading,
  totalCount,
  totalConverted,
  courseId,
  scanId,
  handleCourseScanReload,
  currentPage,
  perPage,
  totalPages,
  onPageChange,
}) => {
  const [showModal, setShowModal] = useState(false)
  const [modalYoutubeEmbeds, setYoutubeModalEmbeds] = useState<Array<YoutubeEmbed>>([])
  const [modalResourceTitle, setModalResourceTitle] = useState('')
  const [modalResourceType, setModalResourceType] = useState('')
  const [modalResourceId, setModalResourceId] = useState(0)

  const handleShowReview = useCallback(
    (youtubeEmbeds: Array<YoutubeEmbed>, resourceTitle: string, resource: YoutubeScanResource) => {
      setYoutubeModalEmbeds(youtubeEmbeds)
      setModalResourceTitle(resourceTitle)
      setModalResourceType(resource.type)
      setModalResourceId(resource.id)
      setShowModal(true)
    },
    [
      setYoutubeModalEmbeds,
      setModalResourceTitle,
      setModalResourceType,
      setModalResourceId,
      setShowModal,
    ],
  )

  const handleModalClose = useCallback(() => {
    setShowModal(false)
  }, [setShowModal])

  // TODO make table responsive
  return (
    <Wrapper handleCourseScan={handleCourseScan} scanButtonDisabled={isRequestLoading}>
      <View
        as="div"
        padding="small"
        margin="medium x-small"
        borderWidth="medium"
        borderRadius="medium"
      >
        <Flex justifyItems="center">
          <Flex.Item>
            <Text size="x-large" weight="bold">
              {totalCount}
            </Text>
          </Flex.Item>
        </Flex>
        <Flex justifyItems="center">
          <Flex.Item>
            <Text size="small">{I18n.t('YouTube content detected')}</Text>
          </Flex.Item>
        </Flex>
        {totalConverted && totalConverted > 0 ? (
          <Flex justifyItems="center" margin="x-small 0 0 0">
            <Flex.Item>
              <Pill color="success">
                <Flex alignItems="center" gap="x-small">
                  <IconCheckSolid size="x-small" />
                  <Text size="small" weight="bold">
                    {I18n.t('%{count} converted', {count: totalConverted})}
                  </Text>
                </Flex>
              </Pill>
            </Flex.Item>
          </Flex>
        ) : null}
      </View>
      <View as="div" borderWidth="small small 0 small" margin="small x-small">
        <EmbedsModal
          showModal={showModal}
          closeModalFunction={handleModalClose}
          youtubeEmbeds={modalYoutubeEmbeds}
          resourceTitle={modalResourceTitle}
          courseId={courseId}
          scanId={scanId}
          handleOnClose={handleCourseScanReload}
          resourceType={modalResourceType}
          resourceId={modalResourceId}
        />
        <Table layout="auto" caption={I18n.t('YouTube content detected table')}>
          <Table.Head>
            <Table.Row>
              <Table.ColHeader
                themeOverride={{padding: '0.90rem 0.75rem'}}
                width="60%"
                id="CanvasResource"
              >
                <Text>{I18n.t('Canvas Resource')}</Text>
              </Table.ColHeader>
              <Table.ColHeader
                themeOverride={{padding: '0.90rem 0.75rem'}}
                width="20%"
                id="ContentType"
              >
                <Text>{I18n.t('Content Type')}</Text>
              </Table.ColHeader>
              <Table.ColHeader
                themeOverride={{padding: '0.90rem 0.75rem'}}
                width="15%"
                textAlign="center"
                id="YoutubeContent"
              >
                <Text>{I18n.t('YouTube Content')}</Text>
              </Table.ColHeader>
              <Table.ColHeader themeOverride={{padding: '0.90rem 0.75rem'}} width="10%" id="Action">
                <Text>{I18n.t('Action')}</Text>
              </Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {resources.map((resource, index) => (
              <Table.Row key={index}>
                <Table.RowHeader themeOverride={{padding: '0.90rem 0.75rem'}}>
                  <Flex alignItems="center" gap="small">
                    <Flex.Item>
                      <Link href={resource.content_url}>
                        <Text weight="normal">{resource.name}</Text>
                      </Link>
                    </Flex.Item>
                    {(() => {
                      const convertedCount = resource.converted_count || 0
                      const isFullyConverted = convertedCount === resource.count
                      if (isFullyConverted) {
                        return (
                          <Flex.Item>
                            <Pill renderIcon={<IconCheckSolid />} color="success" margin="0">
                              {I18n.t('All Converted')}
                            </Pill>
                          </Flex.Item>
                        )
                      }
                      return null
                    })()}
                  </Flex>
                </Table.RowHeader>
                <Table.Cell themeOverride={{padding: '0.90rem 0.75rem'}}>
                  {getResultType(resource.type)}
                </Table.Cell>
                <Table.Cell themeOverride={{padding: '0.90rem 0.75rem'}} textAlign="center">
                  {(() => {
                    const convertedCount = resource.converted_count || 0
                    return <Text>{resource.count - convertedCount}</Text>
                  })()}
                </Table.Cell>
                <Table.Cell themeOverride={{padding: '0.90rem 0.75rem'}}>
                  {(() => {
                    const convertedCount = resource.converted_count || 0
                    const isFullyConverted = convertedCount === resource.count

                    if (isFullyConverted) {
                      return null
                    }

                    return (
                      <Button
                        color="secondary"
                        size="small"
                        onClick={() => handleShowReview(resource.embeds, resource.name, resource)}
                      >
                        {I18n.t('Review')}
                      </Button>
                    )
                  })()}
                </Table.Cell>
              </Table.Row>
            ))}
          </Table.Body>
        </Table>
      </View>
      {totalPages > 1 && (
        <View as="div" margin="medium 0" textAlign="center">
          <Paginator page={currentPage} pageCount={totalPages} loadPage={onPageChange} />
        </View>
      )}
    </Wrapper>
  )
}

const HeaderView: React.FC<{
  scanButtonDisabled?: boolean
  handleCourseScan?: () => void
}> = ({scanButtonDisabled, handleCourseScan}) => {
  return (
    <Flex>
      <Flex.Item padding="x-small" shouldShrink shouldGrow>
        <Heading level="h1" as="h2" margin="0 0 x-small">
          {I18n.t('YouTube Content Migration')}
        </Heading>
        <Text>
          {I18n.t(
            'This tool helps you identify YouTube videos in your course that may display ads. Each row shows a Canvas Page, Module, or Discussion where one or more YouTube videos were found. After migration, videos will be added to the course collection and remain as links, so no extra storage will be used. You can rescan the course anytime with the ‘Scan’ button.',
          )}
        </Text>
      </Flex.Item>
      <Flex.Item align="start">
        <Button
          color="primary"
          margin="small"
          disabled={scanButtonDisabled}
          onClick={handleCourseScan}
        >
          {I18n.t('Scan Course')}
        </Button>
      </Flex.Item>
    </Flex>
  )
}

const Wrapper: React.FC<{
  children: React.ReactNode
  scanButtonDisabled?: boolean
  handleCourseScan?: () => void
}> = ({children, scanButtonDisabled, handleCourseScan}) => {
  return (
    <View as="div">
      <HeaderView scanButtonDisabled={scanButtonDisabled} handleCourseScan={handleCourseScan} />
      {children}
    </View>
  )
}

const youtubeScanQuery = async ({
  signal,
  queryKey,
}: QueryFunctionContext): Promise<YoutubeScanResultReport | undefined> => {
  const [, , courseId, page, perPage] = queryKey
  const fetchOpts = {signal}
  const params = new URLSearchParams()
  if (page) params.append('page', page.toString())
  if (perPage) params.append('per_page', perPage.toString())
  const path = `/api/v1/courses/${courseId}/youtube_migration/scan?${params.toString()}`

  const {json} = await doFetchApi<YoutubeScanResultReport>({path, fetchOpts})

  return json
}

const createYoutubeScanMutation = async ({
  courseId,
}: {
  courseId: string
}): Promise<YoutubeScanResultReport> => {
  const {json, response} = await doFetchApi<YoutubeScanResultReport>({
    path: `/api/v1/courses/${courseId}/youtube_migration/scan`,
    method: 'POST',
  })

  if (!response.ok || json === undefined) {
    throw new Error(I18n.t('Failed to start a scan'))
  }

  return json
}

const onErrorCallbackForScan = () => {
  showFlashError(
    I18n.t('Something went wrong during course scan start. Reload the page and try again.'),
  )()
}

const onSuccessCallbackForScan = (
  courseId: string,
  queryClient: QueryClient,
  resetPagination: () => void,
) => {
  resetPagination()
  queryClient.setQueryData(['youtubeMigration', 'queryLastScan', courseId, 1, 25], {
    workflow_state: YoutubeScanWorkflowState.Queued,
  })
}

export const App: React.FC<AppProps> = ({courseId}) => {
  const isPollingRunning = useRef(false)
  const queryClient = useQueryClient()
  // TODO: until tsc not fails because it can't find mutation.isLoading
  const [isMutationLoading, setIsMutationLoading] = useState(false)
  const [currentPage, setCurrentPage] = useState(1)
  const [perPage, setPerPage] = useState(25)

  const {isLoading, isError, data, refetch} = useQuery({
    queryKey: ['youtubeMigration', 'queryLastScan', courseId, currentPage, perPage],
    queryFn: youtubeScanQuery,
  })

  const resetPagination = () => {
    setCurrentPage(1)
    setPerPage(25)
  }

  const handlePageChange = (page: number) => {
    setCurrentPage(page)
  }

  const mutation = useMutation({
    mutationKey: ['youtubeMigration', 'createScan', courseId],
    mutationFn: createYoutubeScanMutation,
    onSuccess: () => onSuccessCallbackForScan(courseId, queryClient, resetPagination),
    onError: onErrorCallbackForScan,
    onSettled: () => setIsMutationLoading(false),
  })

  useEffect(() => {
    if (
      !isPollingRunning.current &&
      (data?.workflow_state === YoutubeScanWorkflowState.Running ||
        data?.workflow_state === YoutubeScanWorkflowState.Queued ||
        data?.workflow_state === YoutubeScanWorkflowState.WaitingForExternalTool)
    ) {
      isPollingRunning.current = true
      const pollRefetch = async () => {
        const {data} = await refetch()
        if (
          data?.workflow_state === YoutubeScanWorkflowState.Queued ||
          data?.workflow_state === YoutubeScanWorkflowState.Running ||
          data?.workflow_state === YoutubeScanWorkflowState.WaitingForExternalTool
        ) {
          setTimeout(pollRefetch, 1000)
        } else {
          isPollingRunning.current = false
        }
      }
      pollRefetch()
    }
  }, [data?.workflow_state, isPollingRunning, refetch])

  const handleCourseScan = () => {
    setIsMutationLoading(true)
    mutation.mutate({courseId})
  }

  const handleCourseScanReload = () => {
    queryClient.invalidateQueries({queryKey: ['youtubeMigration', 'queryLastScan', courseId]})
  }

  // const mutationInProgress = mutation.isLoading
  const mutationInProgress = isMutationLoading

  if (isLoading) {
    return <LoadingView />
  }

  if (isError || !data) {
    return (
      <GenericErrorPage
        imageUrl={ErrorShip}
        errorSubject={I18n.t('Scan loading error')}
        errorCategory={I18n.t('YouTube Migration Error Page.')}
        errorMessage={I18n.t('Try to reload the page.')}
      />
    )
  }

  if (data.workflow_state == null) {
    return (
      <NoScanFoundView handleCourseScan={handleCourseScan} isRequestLoading={mutationInProgress} />
    )
  }

  if (data.workflow_state === YoutubeScanWorkflowState.Failed) {
    return (
      <LastScanFailedResultView
        handleCourseScan={handleCourseScan}
        isRequestLoading={mutationInProgress}
      />
    )
  }

  if (
    data.workflow_state === YoutubeScanWorkflowState.Queued ||
    data.workflow_state === YoutubeScanWorkflowState.Running ||
    data.workflow_state === YoutubeScanWorkflowState.WaitingForExternalTool ||
    mutationInProgress
  ) {
    return <ScanningInProgressView />
  }

  if (data.workflow_state === YoutubeScanWorkflowState.Completed) {
    if (data.resources.length === 0) {
      return (
        <LastScanEmptyResultView
          handleCourseScan={handleCourseScan}
          isRequestLoading={mutationInProgress}
        />
      )
    }

    return (
      <LastScanResultView
        handleCourseScan={handleCourseScan}
        isRequestLoading={mutationInProgress}
        resources={data.resources}
        totalCount={data.total_count || 0}
        totalConverted={data.total_converted}
        courseId={courseId}
        scanId={data.id}
        handleCourseScanReload={handleCourseScanReload}
        currentPage={data.page || currentPage}
        perPage={data.per_page || perPage}
        totalPages={data.total_pages || 1}
        onPageChange={handlePageChange}
      />
    )
  }
}
