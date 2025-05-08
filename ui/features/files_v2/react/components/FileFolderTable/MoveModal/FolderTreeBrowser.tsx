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

import {forwardRef, useCallback, useImperativeHandle, useRef, useState, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {TreeBrowser} from '@instructure/ui-tree-browser'
import {FormFieldMessage} from '@instructure/ui-form-field'
import {Collection, CollectionData} from '@instructure/ui-tree-browser/types/TreeBrowser/props'
import {View} from '@instructure/ui-view'
import {useFoldersQuery} from './hooks'
import {FolderCollection, addNewFoldersToCollection} from './utils'
import {type Folder} from '../../../../interfaces/File'

export type FolderTreeBrowserRef = {
  validate: () => boolean
}

type FolderTreeBrowserProps = {
  rootFolder: Folder
  onSelectFolder?: (folder: Collection | null) => void
}

const I18n = createI18nScope('files_v2')

const FolderTreeBrowser = forwardRef<FolderTreeBrowserRef, FolderTreeBrowserProps>(
  ({rootFolder, onSelectFolder}, ref) => {
    const containerRef = useRef<Element | null>(null)
    const hasValidSelection = useRef<boolean>(false)
    const [currentFolderId, setCurrentFolderId] = useState<string>(rootFolder.id.toString())
    const [formError, setFormError] = useState<string | null>(null)
    const [folders, setFolders] = useState<FolderCollection>({
      [rootFolder.id]: {id: rootFolder.id, name: rootFolder.name},
    })

    useImperativeHandle(ref, () => ({
      validate: () => {
        let valid = true
        if (!hasValidSelection.current) {
          valid = false
          setFormError(I18n.t('A target folder should be selected.'))
        }
        if (!valid && containerRef.current) {
          const treeElement = containerRef.current.querySelector('ul[role="tree"]')
          if (treeElement) (treeElement as HTMLUListElement).focus()
        }
        return valid
      },
    }))

    const handleCollectionToggle = useCallback(
      (collection: CollectionData) => {
        setFormError(null)
        if (!collection.id) return

        const folder = Object.assign({}, folders[collection.id])
        if (!collection.expanded || folder.collections) return

        setCurrentFolderId(collection.id as string)
      },
      [folders],
    )

    const handleCollectionClick = useCallback(
      (_e: React.MouseEvent, data: CollectionData) => {
        setFormError(null)
        if (!data) return

        let folder = null
        if (data.id) folder = folders[data.id] || null
        onSelectFolder?.(folder)
        hasValidSelection.current = !!folder
      },
      [folders, onSelectFolder],
    )

    const {
      folders: foldersResult,
      foldersLoading,
      foldersError,
    } = useFoldersQuery(currentFolderId as string)

    useMemo(() => {
      if (!foldersLoading && !foldersError && foldersResult) {
        setFolders(originalFolders =>
          addNewFoldersToCollection(originalFolders, currentFolderId as string, foldersResult),
        )
      }
    }, [foldersLoading, foldersError, foldersResult])

    return (
      <>
        {foldersError && (
          <Alert variant="error" renderCloseButtonLabel={I18n.t('Close error message')}>
            {I18n.t('An error occurred while fetching the folders.')}
          </Alert>
        )}
        <View elementRef={(element: Element | null) => (containerRef.current = element)}>
          <TreeBrowser
            size="medium"
            selectionType="single"
            collections={folders}
            items={{}}
            rootId={rootFolder.id}
            defaultExpanded={[rootFolder.id]}
            onCollectionToggle={handleCollectionToggle}
            onCollectionClick={handleCollectionClick}
          />
        </View>
        {formError && (
          <View as="div" margin="x-small none none none">
            <FormFieldMessage variant="newError">{formError}</FormFieldMessage>
          </View>
        )}
      </>
    )
  },
)

export default FolderTreeBrowser
