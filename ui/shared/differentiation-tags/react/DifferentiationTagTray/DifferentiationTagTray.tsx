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
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
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

const I18n = createI18nScope('differentiation_tags')

export interface DifferentiationTagTrayProps {
  isOpen: boolean
  onClose: () => void
  differentiationTagCategories: DifferentiationTagCategory[]
  isLoading: boolean
  error: Error | null
}

const Header = ({onClose}: {onClose: () => void}) => (
  <Flex justifyItems="space-between" width="100%" padding="medium">
    <Flex.Item>
      <Heading level="h2" data-testid="differentiation-tag-header">
        {I18n.t('Manage Tags')}
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

const EmptyState = ({onCreate}: {onCreate: () => void}) => (
  <Flex
    direction="column"
    alignItems="center"
    justifyItems="center"
    padding="medium"
    textAlign="center"
    margin="large 0 0 0"
  >
    <img
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
    <Button onClick={onCreate} margin="large 0 0 0" color="primary" size="medium">
      {I18n.t('Get Started')}
    </Button>
  </Flex>
)

export default function DifferentiationTagTray(props: DifferentiationTagTrayProps) {
  const {isOpen, onClose, differentiationTagCategories, isLoading, error} = props
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create')
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | undefined>(undefined)
  const [currentPage, setCurrentPage] = useState(1)
  const itemsPerPage = 4
  const addTagRef = useRef<HTMLElement | null>(null)
  const focusElRef = useRef<(HTMLElement | null)[]>([])
  const [focusIndex, setFocusIndex] = useState<number | null>(null)

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

  useEffect(() => {
    if (focusIndex === -1) {
      addTagRef.current?.focus()
      setFocusIndex(null)
    } else if (focusIndex !== null) {
      focusElRef.current[focusIndex]?.focus()
    }
  }, [focusIndex])

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

  const categoryCards = useMemo(() => {
    return paginatedCategories.map((category, index) => (
      <TagCategoryCard
        key={category.id}
        category={category}
        onEditCategory={handleEditCategory}
        focusElRef={focusElRef}
        onDeleteFocusFallback={() =>
          setFocusIndex((index >= 1 && paginatedCategories[index - 1]?.id) || -1)
        }
      />
    ))
  }, [paginatedCategories, handleEditCategory, focusElRef])

  const handlePageChange = useCallback((newPage: number) => {
    setCurrentPage(newPage)
  }, [])

  return (
    <View id="manage-differentiation-tag-container" width="100%" display="block">
      <Tray
        onClose={onClose}
        label={I18n.t('Manage Tags')}
        open={isOpen}
        placement="end"
        size="small"
      >
        <Flex direction="column" height="100vh" width="100%">
          <Header onClose={onClose} />

          {differentiationTagCategories.length > 0 && (
            <Flex padding="0 small" direction="column">
              <Flex.Item shouldGrow shouldShrink overflowX="visible" overflowY="visible">
                <DifferentiationTagSearch
                  onSearch={setSearchTerm}
                  delay={300}
                  initialValue={searchTerm}
                />
              </Flex.Item>
              <Flex.Item overflowX="visible" overflowY="visible">
                <Button
                  onClick={handleCreateNewTag}
                  color="primary"
                  margin="x-small none"
                  elementRef={setAddTagRef}
                >
                  {I18n.t('+ Tag')}
                </Button>
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
            <EmptyState onCreate={handleCreateNewTag} />
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
        </Flex>
      </Tray>

      <DifferentiationTagModalManager
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        mode={modalMode}
        differentiationTagCategoryId={selectedCategoryId}
      />
    </View>
  )
}
