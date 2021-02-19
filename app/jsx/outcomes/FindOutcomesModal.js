/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import I18n from 'i18n!FindOutcomesModal'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'
import {Billboard} from '@instructure/ui-billboard'
import {PresentationContent} from '@instructure/ui-a11y'
import 'compiled/jquery.rails_flash_notifications'
import Modal from '../shared/components/InstuiModal'
import SVGWrapper from '../shared/SVGWrapper'
import TreeBrowser from './Management/TreeBrowser'
import {useFindOutcomeModal} from './shared/treeBrowser'
import {useCanvasContext} from './shared/hooks'

const FindOutcomesModal = ({open, onCloseHandler}) => {
  const {contextType} = useCanvasContext()
  const {isLoading, collections, queryCollections, rootId} = useFindOutcomeModal(open)
  const isCourse = contextType === 'Course'
  return (
    <Modal
      open={open}
      onDismiss={onCloseHandler}
      shouldReturnFocus
      size="fullscreen"
      label={isCourse ? I18n.t('Add Outcomes to Course') : I18n.t('Add Outcomes to Account')}
    >
      <Modal.Body padding="0 small small">
        <Flex>
          <Flex.Item
            as="div"
            position="relative"
            width="25%"
            height="calc(100vh - 10.25rem)"
            overflowY="visible"
            overflowX="auto"
          >
            <View as="div" padding="small none none x-small">
              <Heading level="h3">
                <Text size="large" weight="light" fontStyle="normal">
                  {I18n.t('Outcome Groups')}
                </Text>
              </Heading>
              <View>
                {isLoading ? (
                  <div style={{textAlign: 'center', paddingTop: '2rem'}}>
                    <Spinner renderTitle={I18n.t('Loading')} size="large" />
                  </div>
                ) : (
                  <TreeBrowser
                    onCollectionToggle={queryCollections}
                    collections={collections}
                    rootId={rootId}
                  />
                )}
              </View>
            </View>
          </Flex.Item>
          <Flex.Item
            as="div"
            position="relative"
            width="1%"
            height="calc(100vh - 10.25rem)"
            margin="xxx-small 0 0"
            borderWidth="0 small 0 0"
          />
          <Flex.Item
            as="div"
            position="relative"
            width="74%"
            height="calc(100vh - 10.25rem)"
            overflowY="visible"
            overflowX="auto"
          >
            {/* space for outcome items display component */}
            <Flex as="div" height="100%">
              <Flex.Item margin="auto">
                <Billboard
                  size="small"
                  heading={isCourse ? I18n.t('PRO TIP!') : ''}
                  headingLevel="h3"
                  headingAs="h3"
                  hero={
                    <PresentationContent>
                      <SVGWrapper url="/images/outcomes/clipboard_checklist.svg" />
                    </PresentationContent>
                  }
                  message={
                    <View as="div" padding="small 0 xx-large" margin="0 auto" width="60%">
                      <Text size="large" color="primary">
                        {isCourse
                          ? I18n.t(
                              'Save yourself a lot of time by only adding the outcomes that are specific to your course content.'
                            )
                          : I18n.t('Select a group to reveal outcomes here.')}
                      </Text>
                    </View>
                  }
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button type="button" color="primary" margin="0 x-small 0 0" onClick={onCloseHandler}>
          {I18n.t('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default FindOutcomesModal
