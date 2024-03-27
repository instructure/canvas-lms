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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import type {UsedLocation} from '@canvas/grading_scheme/gradingSchemeApiModel'
import {List} from '@instructure/ui-list'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {Spinner} from '@instructure/ui-spinner'

const I18n = useI18nScope('UsedLocationsModal')

type UsedLocationsModalProps = {
  isLoading: boolean
  isOpen: boolean
  sentinelRef?: React.MutableRefObject<null>
  usedLocations: UsedLocation[]
  onClose: () => void
  onDismiss: () => void
}
export const UsedLocationsModal = ({
  isLoading,
  isOpen,
  sentinelRef,
  usedLocations,
  onClose,
  onDismiss,
}: UsedLocationsModalProps) => {
  const [filter, setFilter] = useState<string>('')

  return (
    <Modal
      as="form"
      open={isOpen}
      onClose={onClose}
      onDismiss={onDismiss}
      label={I18n.t('Locations Used')}
      size="small"
      data-testid="used-locations-modal"
    >
      <Modal.Header>
        <CloseButton
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
          onClick={onClose}
          data-testid="used-locations-modal-close-button"
        />
        <Heading>{I18n.t('Locations Used')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0 0 medium">
          <TextInput
            type="search"
            placeholder={I18n.t('Search...')}
            renderBeforeInput={() => <IconSearchLine inline={false} />}
            width="22.5rem"
            value={filter}
            onChange={e => setFilter(e.target.value)}
            renderLabel={<ScreenReaderContent>{I18n.t('Search')}</ScreenReaderContent>}
            data-testid="used-locations-modal-search-input"
          />
        </View>
        <List isUnstyled={true} margin="0 0 0 0">
          {usedLocations.map(course => {
            let filteredAssignments = []
            const courseNameMatches = course.name.toLowerCase().includes(filter.toLowerCase())
            // if there's no filter or the course name matches the filter, return all assignments
            if (filter === '' || courseNameMatches) {
              filteredAssignments = course.assignments
            } else {
              filteredAssignments = course.assignments.filter(assignment =>
                assignment.title.toLowerCase().includes(filter.toLowerCase())
              )
              // if no assignments match the filter nor the course name,
              // don't render the course in the list
              if (filteredAssignments.length === 0) {
                return
              }
            }
            return (
              <List.Item
                margin="x-small 0 0"
                key={`course-${course.id}`}
                data-testid={`used-locations-modal-course-${course.id}`}
              >
                <Flex alignItems="center">
                  <Flex.Item margin="0 x-small 0 0">
                    <Link isWithinText={false} href={`/courses/${course.id}`}>
                      {course.name}
                    </Link>
                  </Flex.Item>
                  <Flex.Item>
                    {course['concluded?'] ? (
                      <Pill>
                        <View as="span" data-testid={`concluded-course-${course.id}-pill`}>
                          {I18n.t('Concluded')}
                        </View>
                      </Pill>
                    ) : (
                      <></>
                    )}
                  </Flex.Item>
                </Flex>
                {filteredAssignments.length > 0 ? (
                  <List isUnstyled={true} key={`assignments-list-${course.id}`}>
                    {filteredAssignments.map(assignment => (
                      <List.Item
                        margin="x-small 0 0"
                        key={`assignment-${assignment.id}`}
                        data-testid={`used-locations-modal-assignment-${assignment.id}`}
                      >
                        <Link
                          isWithinText={false}
                          href={`/courses/${course.id}/assignments/${assignment.id}`}
                        >
                          {assignment.title}
                        </Link>
                      </List.Item>
                    ))}
                  </List>
                ) : (
                  <></>
                )}
              </List.Item>
            )
          })}
        </List>
        {isLoading ? <Spinner renderTitle={I18n.t('Loading')} size="small" /> : <></>}
        <div ref={sentinelRef} style={{height: '1px'}} />
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button onClick={onClose} margin="0 x-small 0 x-small">
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
