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

import React, {useState, useRef, useCallback, useEffect} from 'react'
import {Table} from '@instructure/ui-table'
import {Checkbox} from '@instructure/ui-checkbox'
import {File, Folder} from 'features/files_v2/interfaces/File'
import {type ColumnHeader} from '../../../interfaces/FileFolderTable'
import {getCheckboxLabel, getUniqueId, isFile} from '../../../utils/fileFolderUtils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ModalOrTrayOptions} from '../../../interfaces/FileFolderTable'
import {columnRenderers, type ColumnID} from './FileFolderTableUtils'
import {
  ResolvedName,
  FileOptions,
  FileOptionsResults,
} from '../FilesHeader/UploadButton/FileOptions'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import FileRenameForm from '../FilesHeader/UploadButton/FileRenameForm'
import {sendMoveRequests} from './MoveModal/utils'
import {queryClient} from '@canvas/query'
import $ from 'jquery'
import type {Root} from 'react-dom/client'
import {render} from '@canvas/react'
import DragFeedback from '@canvas/files/react/components/DragFeedback'
import FilesystemObject from '@canvas/files/backbone/models/FilesystemObject'
import {getFilesEnv} from '../../../utils/filesEnvUtils'

// Need to render in this manner to satisfy TypeScript and make sure headers are rendered in stacked view
interface TableBodyProps {
  rows: (File | Folder)[]
  columnHeaders: ColumnHeader[]
  selectedRows: Set<string>
  size: 'small' | 'medium' | 'large'
  isStacked: boolean
  toggleRowSelection: (id: string) => void
  selectRange: (id: string) => void
  userCanEditFilesForContext: boolean
  userCanDeleteFilesForContext: boolean
  userCanRestrictFilesForContext: boolean
  usageRightsRequiredForContext: boolean
  setModalOrTrayOptions: (modalOrTray: ModalOrTrayOptions | null) => () => void
  onPreviewFile?: (file: File) => void
}

const TableBody: React.FC<TableBodyProps> = ({
  rows,
  columnHeaders,
  selectedRows,
  size,
  isStacked,
  toggleRowSelection,
  selectRange,
  userCanEditFilesForContext,
  userCanDeleteFilesForContext,
  userCanRestrictFilesForContext,
  usageRightsRequiredForContext,
  setModalOrTrayOptions,
  onPreviewFile,
}) => {
  const [unresolvedCollisions, setUnresolvedCollisions] = useState<FileOptions[]>([])
  const [fixingNameCollisions, setFixingNameCollisions] = useState<boolean>(false)
  const [destinationFolder, setDestinationFolder] = useState<null | Folder>(null)
  const [dragOverIndex, setDragOverIndex] = useState<number | null>(null)
  const dragHolderRef = useRef<null | JQuery<HTMLElement>>(null)
  const dragRootRef = useRef<null | Root>(null)

  const itemsToDrag = useCallback(() => {
    if (selectedRows.size == 0) {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore Legacy class constructor not typed
      return [new FilesystemObject()]
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore Legacy class constructor not typed
    return Array.from({length: selectedRows.size}, () => new FilesystemObject())
  }, [selectedRows])

  const renderDragFeedback = (e: React.DragEvent) => {
    const {pageX, pageY} = e
    if (!dragHolderRef.current) {
      dragHolderRef.current = $('<div>').appendTo(document.body)
    }
    if (!dragRootRef.current) {
      dragRootRef.current = render(
        <DragFeedback pageX={pageX} pageY={pageY} itemsToDrag={itemsToDrag()} />,
        dragHolderRef.current[0],
      )
    } else {
      dragRootRef.current.render(
        <DragFeedback pageX={pageX} pageY={pageY} itemsToDrag={itemsToDrag()} />,
      )
    }
  }

  const removeDragFeedback = () => {
    if (dragRootRef.current) {
      dragRootRef.current.unmount()
      dragRootRef.current = null
    }
    if (dragHolderRef.current) {
      dragHolderRef.current.remove()
      dragHolderRef.current = null
    }
  }

  const handleDragStart = (e: React.DragEvent, row: File | Folder) => {
    e.dataTransfer.setData('application/x-canvas-file', JSON.stringify(row))
    e.dataTransfer.effectAllowed = 'move'

    // replace the default ghost dragging element with a transparent gif
    const img = new Image()
    img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
    e.dataTransfer.setDragImage(img, 150, 150)

    renderDragFeedback(e)
    document.addEventListener('dragover', handleDocumentDragOver)
    document.addEventListener('dragend', removeDragFeedback)
  }

  const handleDocumentDragOver = (e: DragEvent) => {
    if (!e.dataTransfer?.types.includes('application/x-canvas-file')) {
      return
    }
    renderDragFeedback(e as any)
  }

  const handleDragEnd = () => {
    removeDragFeedback()
    document.removeEventListener('dragover', handleDocumentDragOver)
    document.removeEventListener('dragend', removeDragFeedback)
    setDragOverIndex(null)
  }

  const handleDrop = (e: React.DragEvent, dropFolder: File | Folder) => {
    if (isFile(dropFolder)) return

    const dragItem = JSON.parse(e.dataTransfer.getData('application/x-canvas-file'))

    setDestinationFolder(dropFolder as Folder)
    const dropFolderId = getUniqueId(dropFolder)

    if (dragItem) {
      let selectedItems
      if (selectedRows.size > 0) {
        // If rows are selected, move all selected items
        const selected = rows.filter(row => {
          const rowId = getUniqueId(row)
          return selectedRows.has(rowId) && rowId !== dropFolderId
        })
        selectedItems = selected.map(item => {
          return {
            file: item,
            dup: isFile(item) ? 'error' : 'overwrite', // api only allows overwrite for folders
            name: item.display_name || item.name,
            expandZip: false,
          }
        })
      } else {
        if (getUniqueId(dragItem) === dropFolderId) return // Prevent moving an item into itself
        selectedItems = [
          {
            file: dragItem,
            dup: 'rename',
            name: dragItem.display_name || dragItem.name,
            expandZip: false,
          },
        ]
      }
      if (selectedItems.length > 0)
        sendMoveRequests(dropFolder, resolveCollisions, selectedItems as ResolvedName[])
    }
    handleDragEnd()
  }

  const handleDragEnter = (_e: React.DragEvent, rowIndex: number, row: File | Folder) => {
    if (isFile(row)) {
      setDragOverIndex(null)
      return
    }
    setDragOverIndex(rowIndex)
  }

  const handleDragLeave = (_e: React.DragEvent, rowIndex: number) => {
    if (dragOverIndex === rowIndex) {
      setDragOverIndex(null)
    }
  }

  const resolveCollisions = (nameCollisions: FileOptions[]) => {
    if (nameCollisions.length > 0) {
      FileOptionsCollection.setState({
        nameCollisions: [...nameCollisions],
        resolvedNames: [],
        zipOptions: [],
        newOptions: false,
      })
      setUnresolvedCollisions([...nameCollisions])
      setFixingNameCollisions(true)
    } else {
      queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    }
  }

  const onNameConflictResolved = (fileNameOptions: ResolvedName) => {
    const {resolvedNames, nameCollisions, zipOptions} =
      FileOptionsCollection.getState() as FileOptionsResults
    if (fileNameOptions.dup != 'skip') resolvedNames.push(fileNameOptions)

    const remainingCollisions = [...nameCollisions]
    remainingCollisions.shift()
    FileOptionsCollection.setState({
      nameCollisions: remainingCollisions,
      resolvedNames: resolvedNames,
      zipOptions: zipOptions,
    })
    setUnresolvedCollisions(remainingCollisions)
  }

  useEffect(() => {
    if (unresolvedCollisions.length === 0 && fixingNameCollisions) {
      setFixingNameCollisions(false)

      const resolved = FileOptionsCollection.getState().resolvedNames
      if (resolved.length > 0 && destinationFolder) {
        sendMoveRequests(destinationFolder, resolveCollisions, resolved)
      }
    }
  }, [fixingNameCollisions, unresolvedCollisions.length, destinationFolder])

  const renderHelperModals = () => {
    if (unresolvedCollisions.length === 0) return null

    return (
      <>
        <FileRenameForm
          open={!!unresolvedCollisions.length && fixingNameCollisions}
          onClose={() => {
            FileOptionsCollection.resetState()
            setUnresolvedCollisions(unresolvedCollisions.slice(1))
          }}
          fileOptions={unresolvedCollisions[0]}
          onNameConflictResolved={onNameConflictResolved}
        />
      </>
    )
  }

  const isAccessRestricted = getFilesEnv().userFileAccessRestricted

  return (
    <>
      {rows.map((row, index) => {
        const isSelected = selectedRows.has(getUniqueId(row))
        const handleClick = (event: React.MouseEvent, columnID: ColumnID) => {
          const actionColumns: ColumnID[] = [
            'name',
            'actions',
            'blueprint',
            'permissions',
            'rights',
          ]
          if (actionColumns.includes(columnID)) {
            return // Skip if column's has default click behavior
          }

          if (columnID === 'modified_by' && 'user' in row) {
            return
          }

          if (event.ctrlKey || event.metaKey) {
            toggleRowSelection(getUniqueId(row))
            return
          }
          if (event.shiftKey) {
            selectRange(getUniqueId(row))
            return
          }
        }
        const rowHead = [
          <Table.RowHeader key="select">
            <Checkbox
              label={<ScreenReaderContent>{getCheckboxLabel(row)}</ScreenReaderContent>}
              scope="row"
              size={size}
              checked={isSelected}
              onChange={() => toggleRowSelection(getUniqueId(row))}
              data-testid="row-select-checkbox"
            />
          </Table.RowHeader>,
          ...columnHeaders.map(column => (
            <Table.Cell
              key={column.id}
              data-testid={`table-cell-${column.id}`}
              textAlign={isStacked ? undefined : column.textAlign}
              onClick={e => handleClick(e, column.id)}
            >
              {columnRenderers[column.id]({
                row: row,
                rows: rows,
                isStacked: isStacked,
                userCanEditFilesForContext: userCanEditFilesForContext,
                userCanDeleteFilesForContext: userCanDeleteFilesForContext,
                userCanRestrictFilesForContext: userCanRestrictFilesForContext,
                usageRightsRequiredForContext: usageRightsRequiredForContext,
                size: size,
                isSelected: isSelected,
                toggleSelect: () => toggleRowSelection(getUniqueId(row)),
                setModalOrTrayOptions,
                rowIndex: index,
                onPreviewFile,
              })}
            </Table.Cell>
          )),
        ]
        return (
          <Table.Row
            draggable
            onDragStart={e => !isAccessRestricted && handleDragStart(e, row)}
            onDrop={e => handleDrop(e, row)}
            onDragEnd={handleDragEnd}
            onDragEnter={e => handleDragEnter(e, index, row)}
            onDragLeave={e => handleDragLeave(e, index)}
            key={getUniqueId(row)}
            data-testid="table-row"
            setHoverStateTo={dragOverIndex === index}
          >
            {...rowHead}
          </Table.Row>
        )
      })}
      {renderHelperModals()}
    </>
  )
}

export default TableBody
