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

import React, {useCallback, useEffect, useState, useRef} from 'react'

import {
  CommonMigratorControls,
  RequiredFormLabel,
  ErrorFormMessage,
  noFileSelectedFormMessage,
  FormLabel,
} from '@canvas/content-migrations'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconEndLine, IconFolderLine, IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {TreeBrowser} from '@instructure/ui-tree-browser'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import type {FetchLinkHeader} from '@canvas/do-fetch-api-effect/types'
import type {onSubmitMigrationFormCallback} from '../types'
import MigrationFileInput from './file_input'
import type {TreeBrowserProps} from '@instructure/ui-tree-browser'
import {ImportLabel} from './import_label'
import {ImportInProgressLabel} from './import_in_progress_label'
import {ImportClearLabel} from './import_clear_label'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

type Collection = TreeBrowserProps['collections'][0]
type CollectionClickArgs = TreeBrowserProps['onCollectionClick']

const I18n = createI18nScope('content_migrations_redesign')

type ZipFileImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  fileUploadProgress: number | null
  isSubmitting: boolean
}

type Folder = {
  id: string
  name: string
  full_name: string
  context_id: string
  context_type: string
  parent_folder_id?: string
  workflow_state: string
  created_at: string
  updated_at: string
  locked?: string
  lock_at?: string
  unlock_at?: string
  position?: string
  folders_url?: string
  files_url?: string
  files_count?: string
  folders_count?: string
  hidden?: string
  hidden_for_user?: string
  locked_for_user?: string
  for_submissions?: string
  can_upload?: string
  children: number[]
}

type FetchFoldersResponse = {
  json: Folder[]
  link: FetchLinkHeader
}

type SelectedFolderNameProps = {
  folderName?: string
  clearFolderName: () => void
}

const SelectedFolderName = ({folderName, clearFolderName}: SelectedFolderNameProps) => {
  if (!folderName) {
    return <Text as="div">{I18n.t('No folder selected yet')}</Text>
  }

  return (
    <Flex alignItems="center" gap="x-small">
      <IconFolderLine />
      <Flex.Item shouldShrink shouldGrow>
        <Text weight="bold" size="small">
          <TruncateText>{folderName}</TruncateText>
        </Text>
      </Flex.Item>
      <IconButton
        withBackground={false}
        withBorder={false}
        onClick={clearFolderName}
        screenReaderLabel={I18n.t('Remove folder')}
        size="small"
      >
        <IconEndLine />
      </IconButton>
    </Flex>
  )
}

const ZipFileImporter = ({
  onSubmit,
  onCancel,
  fileUploadProgress,
  isSubmitting,
}: ZipFileImporterProps) => {
  const [folders, setFolders] = useState<Array<Folder>>([])
  const [folder, setFolder] = useState<Folder | null>(null)
  const [file, setFile] = useState<File | null>(null)
  const [searchValue, setSearchValue] = useState('')
  const [fileError, setFileError] = useState<boolean>(false)
  const [folderError, setFolderError] = useState<boolean>(false)
  const fileInputRef = useRef<HTMLInputElement | null>(null)
  const folderInputRef = useRef<HTMLInputElement | null>(null)

  const handleErrorFocus = (hasFileError: boolean, folderError: boolean) => {
    if (hasFileError) {
      fileInputRef.current?.focus()
      return
    }

    if (folderError) {
      folderInputRef.current?.focus()
    }
  }
  const [keyword, setKeyword] = useState('')

  const handleSubmit: onSubmitMigrationFormCallback = useCallback(
    formData => {
      const fileError = !file
      const folderError = !folder

      setFileError(fileError)
      setFolderError(folderError)

      if (fileError || folderError) {
        handleErrorFocus(fileError, folderError)
        return
      }

      formData.pre_attachment = {
        name: file.name,
        size: file.size,
        no_redirect: true,
      }
      formData.settings.folder_id = folder?.id
      onSubmit(formData, file)
    },
    [file, folder, onSubmit],
  )

  useEffect(() => {
    const fetchFolders = (nextLink?: string, accumulatedResults: Folder[] = []) => {
      // Fetch all folders in the course
      doFetchApi({
        path:
          nextLink ||
          `/api/v1/courses/${window.ENV.COURSE_ID}/folders?sort_by=position&per_page=100`,
      })
        // @ts-expect-error
        .then((response: FetchFoldersResponse) => {
          const {json, link} = response
          const folderData = accumulatedResults.concat(json || [])

          if (link?.next) {
            fetchFolders(link.next.url, folderData)
          } else {
            // Organize folders with their children
            const parentFolders: Record<string, number[]> = {}
            folderData.forEach((f: Folder) => {
              if (f.parent_folder_id) {
                if (parentFolders[f.parent_folder_id]) {
                  parentFolders[f.parent_folder_id].push(parseInt(f.id, 10))
                } else {
                  parentFolders[f.parent_folder_id] = [parseInt(f.id, 10)]
                }
              }
            })
            const parentFoldersWithChildren = folderData
            parentFoldersWithChildren.forEach((parentFolder: Folder) => {
              parentFolder.children = parentFolders[parentFolder.id.toString()] || []
            })
            setFolders(parentFoldersWithChildren)
          }
        })
        .catch(showFlashError(I18n.t("Couldn't load folder options")))
    }

    fetchFolders()
  }, [])

  const folderToTreeBrowserCollection = (acc: Record<number, Collection>, f: Folder) => {
    acc[parseInt(f.id, 10)] = {
      id: parseInt(f.id, 10),
      name: f.name,
      collections: searchValue ? [] : f.children || [],
      items: [],
    };
    return acc;
  }

  const folderCollection = () => {
    let filteredFolders = folders

    if (searchValue) {
      filteredFolders = folders.filter((f: Folder) =>
        f.name.toLowerCase().includes(searchValue.toLowerCase()),
      )
    }

    return filteredFolders.reduce(folderToTreeBrowserCollection, {});
  }

  const handleCollectionClick: CollectionClickArgs = (_e, collection) => {
    setFolder(folders.find((f: Folder) => collection.id === parseInt(f.id, 10)) ?? null)
    setFolderError(false)
  }

  const renderClearButton = () => {
    return <>
      {keyword.length ? <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Clear search"
        onClick={() => {
          setKeyword('')
          setSearchValue('')
        }}
      >
        <IconTroubleLine />
      </IconButton> : null}
    </>
  }

  const treeBrowserParams = () => {
    if (searchValue) {
      return {}
    }

    const rootFolderId = folders.find((f: Folder) => f.parent_folder_id === null)?.id
    if (!rootFolderId) {
      return {}
    } else {
      return {
        rootId: rootFolderId,
        defaultExpanded: [rootFolderId],
      }
    }
  }

  const handleSearchSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    showFlashAlert({
      message: I18n.t('Folder Tree Results Updated Below for %{keyword}', {keyword}),
      type: 'info',
      srOnly: true,
      politeness: 'polite',
    })
    setSearchValue(keyword)
  }

  const handleFolderSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setKeyword(e.target.value)
  }

  return (
    <>
      <MigrationFileInput
        fileUploadProgress={fileUploadProgress}
        accepts=".zip"
        onChange={setFile}
        isSubmitting={isSubmitting}
        externalFormMessage={fileError ? noFileSelectedFormMessage : undefined}
        isRequired={true}
        inputRef={ref => (fileInputRef.current = ref)}
      />
      {!isSubmitting && (
        <View as="div" margin="medium none none none" maxWidth="46.5rem">
          {folders.length > 0 ? (
            <>
              <RequiredFormLabel showErrorState={folderError} htmlFor="folder-search">
                {I18n.t('Upload to')}
              </RequiredFormLabel>
              <View as="div" margin="x-small 0 medium" data-testid="fileName">
                {folderError && (
                  <View as="div" margin="0 0 x-small">
                    <ErrorFormMessage>{I18n.t('Please select a folder')}</ErrorFormMessage>
                  </View>
                )}
                <SelectedFolderName
                  folderName={folder?.name}
                  clearFolderName={() => setFolder(null)}
                />
              </View>
              <form onSubmit={handleSearchSubmit}>
                <View as="div" margin="small 0">
                  <FormLabel htmlFor="folder-search">{I18n.t('Search folders')}</FormLabel>
                </View>
                <Flex alignItems ='start'>
                  <TextInput
                    id="folder-search"
                    renderLabel=""
                    placeholder={I18n.t('Search for a folder or file name...')}
                    renderAfterInput={renderClearButton()}
                    value={keyword}
                    onChange={handleFolderSearch}
                    inputRef={ref => (folderInputRef.current = ref)}
                    messages={
                      folderError
                        ? [{text: I18n.t('Please select a folder'), type: 'screenreader-only'}]
                        : []
                    }
                  />
                  <Button
                    margin="0 0 0 small"
                    data-testid="find-assignment-rubric-button"
                    renderIcon={() => <IconSearchLine />}
                    type="submit"
                  >
                    {I18n.t('Search')}
                  </Button>
                </Flex>
              </form>
              <View
                as="div"
                maxHeight="20rem"
                padding="xx-small"
                overflowY="auto"
                overflowX="visible"
                data-testid="folderTree"
              >
                <TreeBrowser
                  collections={folderCollection()}
                  items={{}}
                  sortOrder={(a, b) => {
                    return a.name.localeCompare(b.name)
                  }}
                  onCollectionClick={(id, collection) => {
                    handleCollectionClick(id, collection)
                  }}
                  {...treeBrowserParams()}
                />
              </View>
            </>
          ) : (
            <Spinner renderTitle={I18n.t('Loading folders')} />
          )}
        </View>
      )}
      <CommonMigratorControls
        fileUploadProgress={fileUploadProgress}
        isSubmitting={isSubmitting}
        canSelectContent={false}
        onSubmit={handleSubmit}
        onCancel={onCancel}
        SubmitLabel={ImportLabel}
        SubmittingLabel={ImportInProgressLabel}
        CancelLabel={ImportClearLabel}
      />
    </>
  )
}

export default ZipFileImporter
