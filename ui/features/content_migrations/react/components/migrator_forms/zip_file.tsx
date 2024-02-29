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

import React, {createRef, useCallback, useEffect, useState} from 'react'

import CommonMigratorControls from './common_migrator_controls'
import {humanReadableSize} from '../utils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconTroubleLine, IconUploadLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {TreeBrowser, Collection} from '@instructure/ui-tree-browser'
import {View} from '@instructure/ui-view'
import type {FetchLinkHeader} from '@canvas/do-fetch-api-effect/types'
import type {onSubmitMigrationFormCallback} from '../types'
import MigrationFileInput from './file_input'

const I18n = useI18nScope('content_migrations_redesign')

type ZipFileImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  fileUploadProgress: number | null
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

const ZipFileImporter = ({onSubmit, onCancel, fileUploadProgress}: ZipFileImporterProps) => {
  const [folders, setFolders] = useState<Array<Folder>>([])
  const [folder, setFolder] = useState<Folder | null>(null)
  const fileInput = createRef<HTMLInputElement>()
  const [file, setFile] = useState<File | null>(null)
  const [searchValue, setSearchValue] = useState('')
  const [fileError, setFileError] = useState<boolean>(false)
  const [folderError, setFolderError] = useState<boolean>(false)

  const handleSelectFile = useCallback(() => {
    const files = fileInput.current?.files
    if (!files) {
      return
    }
    const selectedFile = files[0]

    if (selectedFile && ENV.UPLOAD_LIMIT && selectedFile.size > ENV.UPLOAD_LIMIT) {
      setFile(null)
      showFlashError(
        I18n.t('Your migration can not exceed %{file_size}', {
          file_size: humanReadableSize(ENV.UPLOAD_LIMIT),
        })
      )()
    } else {
      setFile(selectedFile)
      setFileError(false)
    }
  }, [fileInput])

  const handleSubmit: onSubmitMigrationFormCallback = useCallback(
    formData => {
      if (!file) {
        setFileError(true)
      }

      if (!folder) {
        setFolderError(true)
      }

      if (!file || !folder) {
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
    [file, folder, onSubmit]
  )

  useEffect(() => {
    const fetchFolders = (nextLink?: string, accumulatedResults: Folder[] = []) => {
      // Fetch all folders in the course
      doFetchApi({
        path:
          nextLink ||
          `/api/v1/courses/${window.ENV.COURSE_ID}/folders?sort_by=position&per_page=100`,
      })
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

  const folderCollection = () => {
    const collection: Record<number, Collection> = {}
    let filteredFolders = folders

    if (searchValue) {
      filteredFolders = folders.filter((f: Folder) =>
        f.name.toLowerCase().includes(searchValue.toLowerCase())
      )
    }
    filteredFolders.forEach((f: Folder) => {
      collection[parseInt(f.id, 10)] = {
        id: parseInt(f.id, 10),
        name: f.name,
        collections: searchValue ? [] : f.children || [],
        items: [],
      }
    })
    return collection
  }

  const handleCollectionClick = (_id: any, collection: Collection) => {
    setFolder(folders.find((f: Folder) => collection.id === parseInt(f.id, 10)) ?? null)
    setFolderError(false)
  }

  const renderClearButton = () => {
    if (!searchValue.length) return

    return (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Clear search"
        onClick={() => {
          setSearchValue('')
        }}
      >
        <IconTroubleLine />
      </IconButton>
    )
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

  return (
    <>
      <MigrationFileInput
        fileUploadProgress={fileUploadProgress}
        accepts=".zip"
        onChange={setFile}
      />
      {fileError && (
        <p>
          <Text color="danger">{I18n.t('You must select a file to import content from')}</Text>
        </p>
      )}
      <View as="div" margin="medium none none none" width="100%">
        {folders.length > 0 ? (
          <>
            <TextInput
              renderLabel={I18n.t('Upload to')}
              placeholder={I18n.t('Search folders')}
              value={searchValue}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                setFolder(null)
                setSearchValue(e.target.value)
              }}
              renderBeforeInput={<IconSearchLine inline={false} />}
              renderAfterInput={renderClearButton()}
            />
            <View as="div" height="320px" padding="xx-small" overflowY="auto" overflowX="visible">
              <TreeBrowser
                collections={folderCollection()}
                items={{}}
                sortOrder={(a, b) => {
                  return a.name.localeCompare(b.name)
                }}
                onCollectionClick={(id, collection) => {
                  handleCollectionClick(id, collection)
                }}
                selectionType="single"
                {...treeBrowserParams()}
              />
            </View>
          </>
        ) : (
          <Spinner renderTitle={I18n.t('Loading folders')} />
        )}
      </View>
      {folderError && (
        <p>
          <Text color="danger">{I18n.t('You must select a folder to import content to')}</Text>
        </p>
      )}
      <CommonMigratorControls
        fileUploadProgress={fileUploadProgress}
        canSelectContent={false}
        onSubmit={handleSubmit}
        onCancel={onCancel}
      />
    </>
  )
}

export default ZipFileImporter
