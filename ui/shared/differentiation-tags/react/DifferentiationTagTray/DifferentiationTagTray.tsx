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
import React, {useState, useMemo, useCallback, useEffect, useRef} from 'react'
import pandasBalloonUrl from '../images/pandasBalloon.svg'
import {Tray} from '@instructure/ui-tray'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconDownloadLine, IconExternalLinkLine, IconUploadLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import DifferentiationTagModalManager from '@canvas/differentiation-tags/react/DifferentiationTagModalForm/DifferentiationTagModalManager'
import TagCategoryCard from './TagCategoryCard'
import {Pagination} from '@instructure/ui-pagination'
import {DifferentiationTagCategory} from '../types'
import DifferentiationTagSearch from './DifferentiationTagSearch'
import UploadFileSVG from '../images/UploadFile.svg'
import {FormMessage} from '@instructure/ui-form-field'
import doFetchApi, {DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {monitorProgress, type CanvasProgress} from '@canvas/progress/ProgressHelpers'

const I18n = createI18nScope('differentiation_tags')

export interface DifferentiationTagTrayProps {
  isOpen: boolean
  onClose: () => void
  differentiationTagCategories: DifferentiationTagCategory[]
  isLoading: boolean
  error: Error | null
  refetchDiffTags: () => void
}

const Header = ({
  onClose,
  showCSVUploadView,
}: {
  onClose: () => void
  showCSVUploadView: boolean
}) => (
  <Flex justifyItems="space-between" width="100%" padding="medium">
    <Flex.Item>
      <Heading level="h2" data-testid="differentiation-tag-header">
        {showCSVUploadView ? I18n.t('Import Tags') : I18n.t('Manage Tags')}
      </Heading>
    </Flex.Item>
    <Flex.Item>
      <CloseButton
        size="medium"
        onClick={onClose}
        screenReaderLabel={I18n.t('Close Differentiation Tag Tray')}
      />
    </Flex.Item>
  </Flex>
)

const EmptyState = ({
  onCreate,
  handleUploadCSV,
}: {
  onCreate: () => void
  handleUploadCSV: () => void
}) => (
  <Flex
    direction="column"
    alignItems="center"
    justifyItems="center"
    padding="medium"
    textAlign="center"
    margin="large 0 0 0"
    data-testid="empty-state"
  >
    <Img
      src={pandasBalloonUrl}
      alt="Pandas Balloon"
      style={{width: '160px', height: 'auto', marginBottom: '1rem'}}
    />
    <Heading level="h3" margin="0 0 medium 0">
      {I18n.t('Differentiation Tags')}
    </Heading>
    <Text size="small">{I18n.t('Like groups, but different!')}</Text>
    <Text as="p" size="small">
      {I18n.t(
        'Tags are not visible to students and can be utilized to assign differentiated work and deadlines to students.',
      )}
    </Text>
    <Text size="small">
      <Link href={I18n.t('#community.differentiation_tags')} isWithinText={false} target="_blank">
        {I18n.t('Learn more about how we used your input to create differentiation tags.')}
      </Link>
    </Text>
    <Button onClick={onCreate} margin="large 0 medium 0" color="primary" size="medium">
      {I18n.t('Get Started')}
    </Button>
    <Text size="small">{I18n.t('Or if you have already created tags with a CSV file,')}</Text>
    <Link
      variant="standalone"
      as={'button'}
      renderIcon={<IconUploadLine />}
      href=""
      onClick={handleUploadCSV}
    >
      {I18n.t('Upload CSV')}
    </Link>
  </Flex>
)

const FileDropLabel = () => (
  <Flex direction="column" justifyItems="center" padding="x-large medium">
    <Flex.Item>
      <Img src={UploadFileSVG} width="120px" />
    </Flex.Item>
    <Flex.Item padding="medium 0 0 0">
      <Flex direction="column" textAlign="center">
        <Flex.Item margin="0 0 small 0" overflowY="visible">
          <Text weight="bold" size="large">
            {I18n.t('Drag and drop tag template file to upload')}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Text color="brand" size="medium">
            {I18n.t('Or choose a file to upload')}
          </Text>
        </Flex.Item>
      </Flex>
    </Flex.Item>
  </Flex>
)

export default function DifferentiationTagTray(props: DifferentiationTagTrayProps) {
  const {isOpen, onClose, differentiationTagCategories, refetchDiffTags, isLoading, error} = props
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [showCSVUploadView, setShowCSVUploadView] = useState(false)
  const [showCSVSpinner, setShowCSVSpinner] = useState(false)
  const [isProcessingCSV, setIsProcessingCSV] = useState(false)
  const [importId, setImportId] = useState<string | null>(null)
  const [errorMessages, setErrorMessages] = useState<FormMessage[]>([])
  const [searchTerm, setSearchTerm] = useState('')
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create')
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | undefined>(undefined)
  const [currentPage, setCurrentPage] = useState(1)
  const [newlyCreatedCategoryId, setNewlyCreatedCategoryId] = useState<number | null>(null)
  const itemsPerPage = 4
  const addTagRef = useRef<HTMLElement | null>(null)
  const focusElRef = useRef<(HTMLElement | null)[]>([])
  const [focusIndex, setFocusIndex] = useState<number | null>(null)

  const handleCreationSuccess = (newCategoryID: number) => {
    setNewlyCreatedCategoryId(newCategoryID)
    if (searchTerm.length === 0) {
      const newPage = Math.ceil((differentiationTagCategories.length + 1) / itemsPerPage)
      setCurrentPage(newPage)
    }
  }

  const setAddTagRef = useCallback((el: Element | null) => {
    if (el instanceof HTMLElement) {
      addTagRef.current = el
    }
  }, [])

  useEffect(() => {
    setCurrentPage(1)
  }, [searchTerm])

  const handleCreateNewTag = () => {
    setModalMode('create')
    setSelectedCategoryId(undefined)
    setIsModalOpen(true)
  }

  const handleUploadCSV = () => {
    setShowCSVUploadView(true)
  }

  useEffect(() => {
    if (focusIndex === -1) {
      addTagRef.current?.focus()
      setFocusIndex(null)
    } else if (focusIndex !== null) {
      focusElRef.current[focusIndex]?.focus()
    }
  }, [focusIndex])

  useEffect(() => {
    if (isProcessingCSV && importId) {
      monitorProgress(importId, checkProgress, handleFailedImport)
    }
  }, [importId, isProcessingCSV])

  const tagImportSuccessMessage = (users: number, groups: number) => {
    if (users === 1) {
      return I18n.t(
        {
          one: 'You successfully uploaded 1 student into %{count} tag.',
          other: 'You successfully uploaded 1 student into %{count} tags.',
        },
        {count: groups},
      )
    }

    if (groups === 1) {
      return I18n.t(
        {
          one: 'You successfully uploaded %{count} student into 1 tag.',
          other: 'You successfully uploaded %{count} students into 1 tag.',
        },
        {count: users},
      )
    }

    return I18n.t('You successfully uploaded %{students} students into %{groups} tags.', {
      groups: groups,
      students: users,
    })
  }

  const checkProgress = (progress: CanvasProgress) => {
    let message
    switch (progress.workflow_state) {
      case 'completed':
        try {
          message =
            typeof progress.message === 'string' ? JSON.parse(progress.message) : progress.message
          if (message.error || message.groups == 0) {
            handleFailedImport()
          } else {
            showFlashAlert({
              message: tagImportSuccessMessage(message.users, message.groups),
              type: 'success',
            })
            setIsProcessingCSV(false)
            setShowCSVSpinner(false)
            refetchDiffTags()
            setShowCSVUploadView(false)
            setImportId(null)
          }
        } catch (e) {
          handleFailedImport()
        }
        break
      case 'failed':
        handleFailedImport()
        break
    }
  }

  const handleFailedImport = () => {
    showFlashAlert({
      message: I18n.t(
        'Upload failed. Make sure all required info is included, the column names match the template, and the file is a CSV.',
      ),
      type: 'error',
    })
    setIsProcessingCSV(false)
    setShowCSVSpinner(false)
    setImportId(null)
  }

  // Filter categories based on the search term.
  const filteredCategories = useMemo(() => {
    if (!searchTerm.trim()) {
      return differentiationTagCategories
    }
    const lowerSearchTerm = searchTerm.toLowerCase()
    return differentiationTagCategories.filter(category => {
      const categoryMatches = category.name.toLowerCase().includes(lowerSearchTerm)
      const groupMatches =
        category.groups &&
        category.groups.some(group => group.name.toLowerCase().includes(lowerSearchTerm))
      return categoryMatches || groupMatches
    })
  }, [differentiationTagCategories, searchTerm])

  const totalPages = Math.ceil(filteredCategories.length / itemsPerPage)

  // Get the categories for the current page from the filtered list.
  const paginatedCategories = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage
    return filteredCategories.slice(startIndex, startIndex + itemsPerPage)
  }, [filteredCategories, currentPage, itemsPerPage])

  const handleEditCategory = useCallback((categoryId: number) => {
    setModalMode('edit')
    setSelectedCategoryId(categoryId)
    setIsModalOpen(true)
  }, [])

  const handleCSVUpload = async (files: ArrayLike<DataTransferItem | File>) => {
    clearErrors()
    setShowCSVSpinner(true)
    if (files.length) {
      await uploadCSV({
        file: files[0],
        onError: () => {
          handleFailedImport()
          return
        },
        onSuccess: () => {
          setIsProcessingCSV(true)
        },
      })
    }
  }

  const uploadCSV = async ({
    file,
    onError,
    onSuccess,
  }: {
    file: DataTransferItem | File
    onError: () => void
    onSuccess: () => void
  }) => {
    try {
      const actualFile = file instanceof DataTransferItem ? file.getAsFile() : file
      if (!actualFile) {
        setErrorMessages([{text: I18n.t('Invalid file selected.'), type: 'newError'}])
        return
      }

      const formData = new FormData()
      formData.append('attachment', actualFile)

      const {json, response}: DoFetchApiResults<any> = await doFetchApi({
        path: `/api/v1/courses/${ENV.course?.id}/group_categories/import_tags`,
        method: 'POST',
        body: formData,
      })

      if (!response.ok) {
        onError()
        return
      }

      setImportId(json.id)
      onSuccess()
    } catch (error) {
      onError()
    }
  }

  const clearErrors = () => {
    setErrorMessages([])
  }

  const handleRejectedFile = (_file: DataTransferItem | File) => {
    setErrorMessages([{text: I18n.t('This file must be csv.'), type: 'newError'}])
  }

  const categoryCards = useMemo(() => {
    return paginatedCategories.map((category, index) => (
      <TagCategoryCard
        key={category.id}
        category={category}
        onEditCategory={handleEditCategory}
        focusElRef={focusElRef}
        onDeleteFocusFallback={() =>
          index >= 1
            ? setFocusIndex(paginatedCategories[index - 1]?.id || -1)
            : (() => {
                const el = document.querySelector('[role="dialog"] button')
                if (el instanceof HTMLElement) el.focus()
              })()
        }
        newlyCreatedCategoryId={newlyCreatedCategoryId}
        onEditButtonBlur={() => setNewlyCreatedCategoryId(null)}
      />
    ))
  }, [paginatedCategories, handleEditCategory, focusElRef, newlyCreatedCategoryId])

  const handlePageChange = useCallback((newPage: number) => {
    setCurrentPage(newPage)
  }, [])

  const manageTagsView = () => (
    <>
      {differentiationTagCategories.length > 0 && (
        <Flex padding="0 small" direction="column" data-testid="manage-tags-view">
          <Flex.Item shouldGrow shouldShrink overflowX="visible" overflowY="visible">
            <DifferentiationTagSearch
              onSearch={setSearchTerm}
              delay={300}
              initialValue={searchTerm}
            />
          </Flex.Item>
          <Flex.Item overflowX="visible" overflowY="visible">
            <Flex justifyItems="space-between">
              <Flex.Item>
                <Button
                  onClick={handleCreateNewTag}
                  color="primary"
                  margin="x-small none"
                  elementRef={setAddTagRef}
                >
                  {I18n.t('+ Tag')}
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button onClick={handleUploadCSV} color="secondary" margin="x-small none">
                  <Flex justifyItems="start">
                    <View as="div" margin="0 xx-small 0 0">
                      <IconUploadLine />
                    </View>
                    {I18n.t('Upload CSV')}
                  </Flex>
                </Button>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      )}

      {isLoading ? (
        <Flex.Item shouldGrow shouldShrink margin="medium">
          <Spinner renderTitle={I18n.t('Loading...')} size="small" />
        </Flex.Item>
      ) : error ? (
        <Flex.Item shouldGrow shouldShrink margin="medium">
          <Text color="danger">
            {I18n.t('Error loading categories:')} {error.message}
          </Text>
        </Flex.Item>
      ) : differentiationTagCategories.length === 0 ? (
        <EmptyState onCreate={handleCreateNewTag} handleUploadCSV={handleUploadCSV} />
      ) : filteredCategories.length === 0 && searchTerm.trim() ? (
        <Flex.Item shouldGrow shouldShrink margin="medium" textAlign="center">
          <Text>{I18n.t('No matching tags found.')}</Text>
        </Flex.Item>
      ) : (
        <Flex.Item shouldGrow shouldShrink margin="none">
          <Flex direction="column" margin="0 small">
            {categoryCards}
          </Flex>
        </Flex.Item>
      )}

      {totalPages > 1 && (
        <Pagination
          data-testid="differentiation-tag-pagination"
          as="nav"
          margin="small"
          variant="compact"
          labelNext={I18n.t('Next Page')}
          labelPrev={I18n.t('Previous Page')}
          currentPage={currentPage}
          totalPageNumber={totalPages}
          onPageChange={handlePageChange}
        />
      )}
    </>
  )

  const csvUploadView = () => (
    <Flex
      direction="column"
      justifyItems="space-between"
      height="100%"
      data-testid="csv-upload-view"
    >
      <Flex direction="column" justifyItems="start">
        <Flex.Item padding="0 medium" margin="0 0 medium 0">
          <Text>
            {I18n.t(
              'You can create tags by downloading the differentiation tag template, editing the file in a spreadsheet editor (like Excel or Google Sheets) and then uploading your edited file.',
            )}
          </Text>
        </Flex.Item>
        <Flex.Item padding="xx-small medium" margin="0 0 large 0">
          <Link
            variant="standalone"
            renderIcon={IconDownloadLine}
            href={`/api/v1/courses/${ENV.course?.id}/group_categories/export_tags`}
          >
            {I18n.t('Download Template File')}
          </Link>
          <Link
            variant="standalone"
            renderIcon={<IconExternalLinkLine />}
            href="/doc/api/file.differentiation_tags_csv.html"
          >
            {I18n.t('Read Tag Import Instructions')}
          </Link>
        </Flex.Item>
        <Flex.Item padding="large small">
          {showCSVSpinner ? (
            <Flex direction="row" justifyItems="center">
              <Flex.Item>
                <Spinner renderTitle="Loading" size="large" />
              </Flex.Item>
            </Flex>
          ) : (
            <FileDrop
              renderLabel={<FileDropLabel />}
              accept=".csv"
              onDropAccepted={(files, _e) => handleCSVUpload(files)}
              onDropRejected={(files, _e) => {
                const [file] = Array.from(files)
                handleRejectedFile(file)
              }}
              onClick={clearErrors}
              messages={errorMessages}
            />
          )}
        </Flex.Item>
      </Flex>
      {!showCSVSpinner && (
        <Flex.Item as="footer" align="end" padding="small">
          <Button
            type="button"
            color="secondary"
            onClick={() => setShowCSVUploadView(false)}
            margin="small 0 0 0"
          >
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
      )}
    </Flex>
  )

  return (
    <View id="manage-differentiation-tag-container" width="100%" display="block">
      <Tray
        onClose={onClose}
        label={showCSVUploadView ? I18n.t('Import Tags') : I18n.t('Manage Tags')}
        open={isOpen}
        placement="end"
        size="small"
      >
        <Flex direction="column" height="100vh" width="100%">
          <Header onClose={onClose} showCSVUploadView={showCSVUploadView} />

          {showCSVUploadView ? csvUploadView() : manageTagsView()}
        </Flex>
      </Tray>

      <DifferentiationTagModalManager
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        mode={modalMode}
        differentiationTagCategoryId={selectedCategoryId}
        onCreationSuccess={handleCreationSuccess}
      />
    </View>
  )
}
