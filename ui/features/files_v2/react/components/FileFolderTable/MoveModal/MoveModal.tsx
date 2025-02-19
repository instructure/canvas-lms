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

import {createRef, Ref, useCallback, useContext, useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert, showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {queryClient} from '@canvas/query'
import {Modal} from '@instructure/ui-modal'
import {Collection} from '@instructure/ui-tree-browser/types/TreeBrowser/props'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import {FileManagementContext} from '../../Contexts'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {isFile} from '../../../../utils/fileFolderUtils'
import {type Folder, type File} from '../../../../interfaces/File'
import FolderTreeBrowser, {FolderTreeBrowserRef} from './FolderTreeBrowser'
import FileRenameForm from '../../FilesHeader/UploadButton/FileRenameForm'
import {FileOptionsResults} from '../../FilesHeader/UploadButton/FileOptions'
import {FileFolderWrapper, BBFolderWrapper} from '../../../../utils/fileFolderWrappers'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'

export type MoveModalProps = {
  open: boolean
  items: (File | Folder)[]
  onDismiss: () => void
}

const I18n = createI18nScope('files_v2')

const MoveModal = ({open, items, onDismiss}: MoveModalProps) => {
  const {contextType, contextId, rootFolder} = useContext(FileManagementContext)
  const folderTreeBrowserRef: Ref<FolderTreeBrowserRef> = createRef<FolderTreeBrowserRef>()
  const [selectedFolder, setSelectedFolder] = useState<Collection | null>(null)
  const [postStatus, setPostStatus] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)
  const [fixingNameCollisions, setFixingNameCollisions] = useState<boolean>(false)
  const [fileOptions, setFileOptions] = useState<FileOptionsResults>(() =>
    FileOptionsCollection.getState(),
  )

  const resetState = useCallback(() => {
    setSelectedFolder(null)
    setPostStatus(false)
    setError(null)
    setFixingNameCollisions(false)
    setFileOptions(FileOptionsCollection.getState())
  }, [])

  const startMoveOperation = useCallback(() => {
    const body = {
      parent_folder_id: selectedFolder?.id,
    }
    const {resolvedNames} = FileOptionsCollection.getState() as FileOptionsResults

    showFlashAlert({message: I18n.t('Starting copy operation...')})
    return Promise.all(
      resolvedNames.map(options => {
        let additionalParams
        if (options.dup === 'overwrite') {
          additionalParams = {
            on_duplicate: 'overwrite',
          }
        } else if (options.dup === 'rename') {
          if (options.name) {
            additionalParams = {
              display_name: options.name,
              name: options.name,
              on_duplicate: 'rename',
            }
          } else {
            additionalParams = {
              on_duplicate: 'rename',
            }
          }
        }
        const item = options.file as File | Folder

        return doFetchApi<File | Folder>({
          method: 'PUT',
          path: `/api/v1/${isFile(item) ? 'files' : 'folders'}/${item.id}`,
          body: {...body, ...additionalParams},
        })
          .then(response => response.json)
          .then((responseItem?: File | Folder) => {
            showFlashSuccess(
              I18n.t('%{name} successfully moved to %{folderName}', {
                name: responseItem?.display_name || responseItem?.filename || responseItem?.name,
                folderName: selectedFolder?.name,
              }),
            )()
          })
          .catch(
            showFlashError(
              I18n.t('Error moving %{name} to %{folderName}', {
                name: item.display_name || item.filename || item.name,
                folderName: selectedFolder?.name,
              }),
            ),
          )
      }),
    )
  }, [selectedFolder])

  useEffect(() => {
    if (fileOptions.nameCollisions.length === 0 && fixingNameCollisions) {
      setFixingNameCollisions(false)

      if (fileOptions.resolvedNames.length > 0) {
        startMoveOperation()
          .then(onDismiss)
          .then(() => queryClient.refetchQueries({queryKey: ['files'], type: 'active'}))
      } else {
        onDismiss()
      }
    }
  }, [
    fileOptions.nameCollisions.length,
    fileOptions.resolvedNames.length,
    fixingNameCollisions,
    onDismiss,
    startMoveOperation,
  ])

  const fetchFolderData = useCallback(() => {
    return doFetchApi<(File | Folder)[]>({
      path: `/api/v1/folders/${selectedFolder?.id}/all`,
    })
      .then(response => response.json)
      .then(data => {
        if (!data) throw new Error()

        const folderWrapper = new BBFolderWrapper(selectedFolder as Folder)
        const foldersAndFiles = data.map((row: File | Folder) => new FileFolderWrapper(row))
        folderWrapper.files.set(foldersAndFiles)
        return folderWrapper
      })
  }, [selectedFolder])

  const checkNameCollisions = useCallback(
    (folder: BBFolderWrapper) => {
      FileOptionsCollection.setFolder(folder)

      const filesAndFolders = items.map(item =>
        isFile(item)
          ? {
              file: {
                ...item,
                name: item.display_name || item.filename || item.name,
              },
            }
          : {
              file: item,
              // API doesn't support other options for folders
              dup: 'overwrite',
            },
      )
      const {collisions, resolved, zips} =
        FileOptionsCollection.segregateOptionBuckets(filesAndFolders)
      FileOptionsCollection.setState({
        nameCollisions: collisions,
        resolvedNames: resolved,
        zipOptions: zips,
        // Does not queue the uploads
        newOptions: false,
      })
      return FileOptionsCollection.getState()
    },
    [items],
  )

  const handleMoveClick = useCallback(async () => {
    if (!folderTreeBrowserRef.current?.validate()) return

    setPostStatus(true)
    try {
      const folderData = await fetchFolderData()

      const fileOptions = checkNameCollisions(folderData)
      setFileOptions(fileOptions)

      if (fileOptions.nameCollisions.length > 0) {
        setFixingNameCollisions(true)
      } else {
        await startMoveOperation()
        onDismiss()
        queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
      }
    } catch (_) {
      setError(I18n.t('Failed to load folder data.'))
    } finally {
      setPostStatus(false)
    }
  }, [checkNameCollisions, fetchFolderData, folderTreeBrowserRef, onDismiss, startMoveOperation])

  const renderHelperModals = () => {
    if (!fileOptions) return null

    const nameCollisions = fileOptions.nameCollisions
    if (nameCollisions.length === 0) return null

    return (
      <>
        <FileRenameForm
          open={!!nameCollisions.length && fixingNameCollisions}
          onClose={() => {
            FileOptionsCollection.resetState()
            setFileOptions(FileOptionsCollection.getState())
          }}
          fileOptions={nameCollisions[0]}
          onNameConflictResolved={fileNameOptions => {
            FileOptionsCollection.onNameConflictResolved(fileNameOptions)
            setFileOptions(FileOptionsCollection.getState())
          }}
        />
      </>
    )
  }

  const renderHeader = useCallback(
    () => (
      <>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Move To...')}</Heading>
      </>
    ),
    [onDismiss],
  )

  const renderBody = useCallback(() => {
    if (!rootFolder) return null

    if (postStatus) {
      return (
        <View as="div" textAlign="center">
          <Spinner
            renderTitle={() => I18n.t('Moving items')}
            aria-live="polite"
            data-testid="move-spinner"
          />
        </View>
      )
    }

    const context = filesEnv.contextFor({
      contextType,
      contextId,
    })
    rootFolder.name = context?.name || rootFolder.custom_name || rootFolder.name

    let text
    if (items.length > 1) {
      text = I18n.t('Where would you like to move these items?')
    } else {
      text = isFile(items[0])
        ? I18n.t('Where would you like to move this file?')
        : I18n.t('Where would you like to move this folder?')
    }

    return (
      <>
        <FileFolderInfo items={items} />
        <View as="div" padding="small none">
          <Text weight="bold">{text}</Text>
        </View>
        {error && (
          <Alert variant="error" renderCloseButtonLabel={I18n.t('Close error message')}>
            {error}
          </Alert>
        )}
        <FolderTreeBrowser
          ref={folderTreeBrowserRef}
          rootFolder={rootFolder}
          onSelectFolder={setSelectedFolder}
        />
      </>
    )
  }, [rootFolder, postStatus, items, error, folderTreeBrowserRef, contextType, contextId])

  const renderFooter = useCallback(() => {
    return (
      <>
        <Button
          data-testid="move-cancel-button"
          margin="0 x-small 0 0"
          disabled={postStatus}
          onClick={onDismiss}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          data-testid="move-move-button"
          color="primary"
          onClick={handleMoveClick}
          disabled={postStatus}
        >
          {I18n.t('Move')}
        </Button>
      </>
    )
  }, [handleMoveClick, onDismiss, postStatus])

  if (items.length === 0 || !rootFolder) return null

  return (
    <>
      <Modal
        open={open && !fixingNameCollisions}
        onDismiss={onDismiss}
        size="small"
        label={I18n.t('Copy')}
        shouldCloseOnDocumentClick={false}
        onExited={resetState}
      >
        <Modal.Header>{renderHeader()}</Modal.Header>
        <Modal.Body>{renderBody()}</Modal.Body>
        <Modal.Footer>{renderFooter()}</Modal.Footer>
      </Modal>
      {renderHelperModals()}
    </>
  )
}

export default MoveModal
