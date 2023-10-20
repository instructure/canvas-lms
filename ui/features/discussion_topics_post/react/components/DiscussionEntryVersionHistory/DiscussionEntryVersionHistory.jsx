/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import PropTypes from 'prop-types'
import {DiscussionEntryVersion} from '../../../graphql/DiscussionEntryVersion'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import DateHelper from '@canvas/datetime/dateHelper'
import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_posts')

export const DiscussionEntryVersionHistory = props => {
  const [open, setOpen] = useState(false)
  const [expanded, setExpanded] = useState([])
  const [isExpandedAll, setIsExpandedAll] = useState(false)

  const setAllExpandedTo = value => {
    const newExpanded = [...expanded]
    props.discussionEntryVersions.forEach((version, index) => {
      newExpanded[index] = value
    })
    setExpanded(newExpanded)
  }

  const setExpandedForIndex = (index, value) => {
    const newExpanded = [...expanded]
    newExpanded[index] = value
    setExpanded(newExpanded)
  }

  const closeAndReset = () => {
    setOpen(false)
    setAllExpandedTo(false)
    setIsExpandedAll(false)
  }

  const expandCollapseAllButtonText = isExpandedAll ? I18n.t('Collapse all') : I18n.t('Expand all')

  return (
    <>
      <Flex.Item overflowX="hidden" padding="0 xx-small 0 0">
        <Text size={props.textSize}>
          <Link
            as="button"
            onClick={() => {
              setOpen(true)
            }}
            margin="0 0 small 0"
          >
            {I18n.t('View History')}
          </Link>
        </Text>
      </Flex.Item>
      <Modal
        as="form"
        open={open}
        onDismiss={() => {
          closeAndReset()
        }}
        size="medium"
        label={I18n.t('Edit History')}
        shouldCloseOnDocumentClick={true}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            onClick={() => {
              closeAndReset()
            }}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Edit History')}</Heading>
        </Modal.Header>
        <Modal.Body padding="small">
          <Flex justifyItems="end">
            <Flex.Item margin="xx-small">
              <Button
                size="small"
                onClick={() => {
                  if (isExpandedAll) {
                    setAllExpandedTo(false)
                  } else {
                    setAllExpandedTo(true)
                  }
                  setIsExpandedAll(!isExpandedAll)
                }}
              >
                {expandCollapseAllButtonText}
              </Button>
            </Flex.Item>
          </Flex>
          {props.discussionEntryVersions.map((version, i) => {
            const updatedAt = DateHelper.formatDatetimeForDiscussions(version.updatedAt)

            return (
              <View as="div" margin="x-small 0 0" key={'v' + version.version}>
                <ToggleDetails
                  expanded={expanded[i]}
                  onToggle={(event, expanded) => {
                    setExpandedForIndex(i, expanded)
                  }}
                  variant="filled"
                  summary={
                    i === 0
                      ? I18n.t('Latest Version %{updatedAt}', {updatedAt})
                      : I18n.t('Version %{versionNumber} %{updatedAt}', {
                          versionNumber: version.version,
                          updatedAt,
                        })
                  }
                  data-testid={'v' + version.version + '-toggle'}
                >
                  <div dangerouslySetInnerHTML={{__html: version.message}} />
                </ToggleDetails>
              </View>
            )
          })}
        </Modal.Body>
        <Modal.Footer>
          <Button
            onClick={() => {
              closeAndReset()
            }}
            color="primary"
            margin="0 x-small 0 0"
          >
            {I18n.t('Close')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}

DiscussionEntryVersionHistory.propTypes = {
  textSize: PropTypes.string,
  discussionEntryVersions: PropTypes.arrayOf(DiscussionEntryVersion.shape),
}
