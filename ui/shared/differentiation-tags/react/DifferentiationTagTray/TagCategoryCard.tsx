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

import React, {useState, useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import TagInfo from './TagInfo'
import {DifferentiationTagCategory} from '../types'
import {useDeleteDifferentiationTagCategory} from '../hooks/useDeleteDifferentiationTagCategory'
import {DeleteTagWarningModal} from '../WarningModal'
import TruncateTextWithTooltip from '../components/TruncateTextWithTooltip'

const I18n = createI18nScope('differentiation_tags')

export interface TagCategoryCardProps {
  category: DifferentiationTagCategory
  onEditCategory: (id: number) => void
  onDeleteFocusFallback?: () => void
  focusElRef?: React.MutableRefObject<(HTMLElement | null)[]>
}

function TagCategoryCard({
  category,
  onEditCategory,
  onDeleteFocusFallback,
  focusElRef,
}: TagCategoryCardProps) {
  const {name, groups = []} = category

  const deleteMutation = useDeleteDifferentiationTagCategory()
  const [isWarningModalOpen, setIsWarningModalOpen] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  const mode = useMemo(() => {
    if (groups.length === 0) {
      return 'EMPTY_TAG_MODE'
    }
    if (groups.length === 1 && groups[0].name === name) {
      return 'SINGLE_TAG_MODE'
    }
    return 'MULTI_TAG_MODE'
  }, [groups, name])

  const handleEdit = (event: React.KeyboardEvent<any> | React.MouseEvent<any, MouseEvent>) => {
    event.preventDefault()
    onEditCategory(category.id)
  }

  const handleDelete = () => {
    setDeleteError(null)
    setIsWarningModalOpen(true)
  }

  const handleConfirmDelete = () => {
    deleteMutation.mutate(
      {differentiationTagCategoryId: category.id},
      {
        onSuccess: () => {
          setIsWarningModalOpen(false)
          if (onDeleteFocusFallback) {
            onDeleteFocusFallback()
          }
        },
        onError: (error: Error) => {
          setDeleteError(error.message)
        },
      },
    )
  }

  const handleCancelDelete = () => {
    setIsWarningModalOpen(false)
    setDeleteError(null)
  }

  return (
    <>
      <View
        padding="small medium"
        margin="small 0"
        display="block"
        borderWidth="small"
        role="group"
        aria-label={name}
      >
        <Flex justifyItems="space-between" width="100%">
          <Flex.Item shouldGrow shouldShrink>
            <Flex direction="column">
              <Flex.Item>
                <TruncateTextWithTooltip>
                  <div data-testid="full-tag-name">{name}</div>
                </TruncateTextWithTooltip>
              </Flex.Item>
              <Flex.Item>
                {mode === 'EMPTY_TAG_MODE' && (
                  <View margin="0 0 small 0" as="div">
                    <Text size="small" color="secondary">
                      {I18n.t('No tags in tag set')}
                    </Text>
                  </View>
                )}

                {mode === 'SINGLE_TAG_MODE' && (
                  <View margin="0 0 small 0" as="div">
                    <Text size="small" color="secondary">
                      {I18n.t('Single tag')}
                    </Text>
                  </View>
                )}
              </Flex.Item>
            </Flex>
          </Flex.Item>

          <Flex.Item align="start" margin="0 0 0 small" shouldShrink={false}>
            <Flex>
              <Flex.Item margin="0 x-small 0 0">
                <IconButton
                  color="primary"
                  size="small"
                  withBackground={false}
                  withBorder={false}
                  screenReaderLabel={I18n.t('Edit')}
                  onClick={handleEdit}
                  aria-label={I18n.t('Edit tag set: %{name}', {name})}
                >
                  <IconEditLine />
                </IconButton>
              </Flex.Item>
              <Flex.Item>
                <IconButton
                  elementRef={el => {
                    if (focusElRef?.current && el instanceof HTMLElement) {
                      focusElRef.current[category.id] = el
                    }
                  }}
                  color="primary"
                  size="small"
                  withBackground={false}
                  withBorder={false}
                  screenReaderLabel={I18n.t('Delete %{name}', {name})}
                  onClick={handleDelete}
                >
                  <IconTrashLine />
                </IconButton>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>

        <TagInfo tags={groups} onEdit={handleEdit} multiMode={mode === 'MULTI_TAG_MODE'} />
      </View>

      <DeleteTagWarningModal
        open={isWarningModalOpen}
        onClose={handleCancelDelete}
        onContinue={handleConfirmDelete}
        isLoading={deleteMutation.isPending}
      >
        {deleteError && <Text color="danger">{deleteError}</Text>}
      </DeleteTagWarningModal>
    </>
  )
}

export default React.memo(TagCategoryCard)
