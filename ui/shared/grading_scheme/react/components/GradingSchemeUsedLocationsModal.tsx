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
import {Modal} from '@instructure/ui-modal'
import {UsedLocation} from '@canvas/grading_scheme/gradingSchemeApiModel'
import {Heading} from '@instructure/ui-heading'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'
import {Pill} from '@instructure/ui-pill'

const I18n = useI18nScope('GradingSchemeViewModal')

type Props = {
  open: boolean
  usedLocations?: UsedLocation[]
  handleClose: () => void
}
const GradingSchemeUsedLocationsModal = ({open, usedLocations, handleClose}: Props) => {
  const [filter, setFilter] = useState<string>('')
  if (!usedLocations) {
    return <></>
  }
  return (
    <Modal
      as="form"
      open={open}
      onDismiss={handleClose}
      label={I18n.t('Locations Used')}
      size="small"
    >
      <Modal.Header>
        <CloseButton
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
          onClick={handleClose}
        />
        <Heading>{I18n.t('Locations Used')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0 0 x-small 0">
          <TextInput
            type="search"
            placeholder={I18n.t('Search...')}
            renderBeforeInput={() => <IconSearchLine inline={false} />}
            width="22.5rem"
            value={filter}
            onChange={e => setFilter(e.target.value)}
          />
        </View>
        <List isUnstyled={true} margin="0 0 0 0">
          {usedLocations.map(course => {
            let filteredAssignments = course.assignments
            if (filter !== '') {
              filteredAssignments = course.assignments.filter(assignment =>
                assignment.title.toLowerCase().includes(filter.toLowerCase())
              )
            }
            if (
              filteredAssignments.length === 0 &&
              !course.name.toLowerCase().includes(filter.toLowerCase())
            ) {
              return <></>
            }
            return (
              <>
                <List.Item margin="0 0 x-small 0">
                  <Flex alignItems="center">
                    <Flex.Item margin="0 xx-small 0 0">
                      <Link isWithinText={false} href={`/courses/${course.id}`}>
                        {course.name}
                      </Link>
                    </Flex.Item>
                    <Flex.Item>
                      {course.concluded ? <Pill>{I18n.t('Concluded')}</Pill> : <></>}
                    </Flex.Item>
                  </Flex>
                </List.Item>

                {filteredAssignments.length > 0 ? (
                  <List isUnstyled={true}>
                    {filteredAssignments.map(assignment => (
                      <List.Item margin="0 0 x-small 0">
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
              </>
            )
          })}
        </List>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button onClick={handleClose} margin="0 x-small 0 x-small">
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default GradingSchemeUsedLocationsModal
