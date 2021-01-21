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
import {PresentationContent} from '@instructure/ui-a11y'
import {Billboard} from '@instructure/ui-billboard'
import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenDownLine, IconArrowOpenEndLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TreeBrowser} from '@instructure/ui-tree-browser'
import {View} from '@instructure/ui-view'
import 'compiled/jquery.rails_flash_notifications'
import I18n from 'i18n!OutcomeManagement'
import $ from 'jquery'
import React, {useEffect, useState} from 'react'
import {useApolloClient} from 'react-apollo'
import SVGWrapper from '../../shared/SVGWrapper'
import {CHILD_GROUPS_QUERY} from './api'
import OutcomeGroupHeader from './OutcomeGroupHeader'

const groupDescriptor = ({childGroupsCount, outcomesCount}) => {
  return I18n.t('%{groups} Groups | %{outcomes} Outcomes', {
    groups: childGroupsCount,
    outcomes: outcomesCount
  })
}

const mergeStateGroups = (group, collections, parentGroupId) => {
  const groups = group?.childGroups?.nodes || []
  const newCollections = groups.reduce((memo, g) => {
    return {
      ...memo,
      [g._id]: {
        id: g._id,
        name: g.title,
        descriptor: groupDescriptor(g),
        collections: []
      }
    }
  }, collections)

  if (newCollections[parentGroupId]) {
    newCollections[parentGroupId] = {
      ...newCollections[parentGroupId],
      loadInfo: 'loaded',
      collections: [...newCollections[parentGroupId].collections, ...groups.map(g => g._id)]
    }
  }

  return newCollections
}

const NoOutcomesBillboard = ({contextType}) => {
  const isCourse = contextType === 'Course'

  return (
    <div className="management-panel" data-testid="outcomeManagementPanel">
      <Billboard
        size="large"
        headingLevel="h3"
        heading={
          isCourse
            ? I18n.t('Outcomes have not been added to this course yet.')
            : I18n.t('Outcomes have not been added to this account yet.')
        }
        message={
          isCourse
            ? I18n.t('Get started by finding, importing or creating your course outcomes.')
            : I18n.t('Get started by finding, importing or creating your account outcomes.')
        }
        hero={
          <div>
            <PresentationContent>
              <SVGWrapper url="/images/magnifying_glass.svg" />
            </PresentationContent>
          </div>
        }
      />
    </div>
  )
}

// TreeBrowser rootId prop needs to be a number
const ROOT_ID = 0

const OutcomeManagementPanel = ({contextType, contextId}) => {
  const isCourse = contextType === 'Course'
  const [initialLoading, setInitialLoading] = useState(true)
  const [error, setError] = useState(null)
  const client = useApolloClient()
  const [collections, setCollections] = useState({
    [ROOT_ID]: {
      id: ROOT_ID,
      collections: [],
      outcomesCount: 0,
      loadInfo: 'loading'
    }
  })

  useEffect(() => {
    client
      .query({
        query: CHILD_GROUPS_QUERY,
        variables: {
          id: contextId,
          type: contextType
        }
      })
      .then(({data}) => {
        setCollections(mergeStateGroups(data?.context?.rootOutcomeGroup, collections, ROOT_ID))
      })
      .finally(() => {
        setInitialLoading(false)
      })
      .catch(err => {
        setError(err)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const onCollectionToggle = ({id}) => {
    if (!['loaded', 'loading'].includes(collections[id].loadInfo)) {
      const newCollections = {
        ...collections,
        [id]: {
          ...collections[id],
          loadInfo: 'loading'
        }
      }
      setCollections(newCollections)

      client
        .query({
          query: CHILD_GROUPS_QUERY,
          variables: {
            id,
            type: 'LearningOutcomeGroup'
          }
        })
        .then(({data}) => {
          setCollections(mergeStateGroups(data?.context, collections, id))
        })
        .catch(err => {
          setError(err)
        })
    }
  }

  useEffect(() => {
    if (error) {
      isCourse
        ? $.flashError(I18n.t('An error occurred while loading course outcomes.'))
        : $.flashError(I18n.t('An error occurred while loading account outcomes.'))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [error])

  if (initialLoading) {
    return (
      <div style={{textAlign: 'center'}}>
        <Spinner renderTitle={I18n.t('Loading')} size="large" />
      </div>
    )
  }

  if (error) {
    return (
      <div>
        <Text color="danger">
          {isCourse
            ? I18n.t('An error occurred while loading course outcomes: %{error}', {error})
            : I18n.t('An error occurred while loading account outcomes: %{error}', {error})}
        </Text>
      </div>
    )
  }

  // Currently we're checking the presence of outcomes by checking the presence of folders
  // we need to implement the correct behavior later
  // https://gerrit.instructure.com/c/canvas-lms/+/255898/8/app/jsx/outcomes/Management/index.js#235
  const hasOutcomes = Object.keys(collections).length > 1

  return (
    <div className="management-panel" data-testid="outcomeManagementPanel">
      {!hasOutcomes ? (
        <NoOutcomesBillboard contextType={contextType} />
      ) : (
        <Flex>
          <Flex.Item width="33%" display="inline-block" position="relative" height="50vh" as="div">
            <View padding="small none none x-small">
              <Text size="large" weight="light" fontStyle="normal">
                {I18n.t('Outcome Groups')}
              </Text>
              <div>
                <TreeBrowser
                  margin="small 0 0"
                  collections={collections}
                  items={{}}
                  onCollectionToggle={onCollectionToggle}
                  collectionIcon={() => (
                    <span style={{display: 'inline-block', marginRight: '0.8em'}}>
                      <IconArrowOpenEndLine size="x-small" />
                    </span>
                  )}
                  collectionIconExpanded={() => (
                    <span style={{display: 'inline-block', marginRight: '0.8em'}}>
                      <IconArrowOpenDownLine size="x-small" />
                    </span>
                  )}
                  rootId={ROOT_ID}
                  showRootCollection={false}
                />
              </div>
            </View>
          </Flex.Item>
          <Flex.Item
            width="1%"
            display="inline-block"
            position="relative"
            padding="small none large none"
            margin="small none none none"
            borderWidth="none small none none"
            height="50vh"
            as="div"
          />
          <Flex.Item width="66%" display="inline-block" position="relative" height="50vh" as="div">
            <View padding="small none none x-small">
              {/* space for outcome group display component */}
              {/* OutcomeGroupHeader for QA purposes
               * Remove component after integration
               * with outcome group display component
               */}
              <View as="div" padding="0 medium">
                <OutcomeGroupHeader
                  title="Grade.2.Math.3A.Elementary.5B.Calculus.1C"
                  description={'<p>This is a <strong><em>description</em></strong>. And because it’s so <strong>long</strong>, it will run out of space and hence be truncated. </p>'.repeat(
                    3
                  )}
                  onMenuHandler={() => {}}
                />
              </View>
            </View>
          </Flex.Item>
        </Flex>
      )}
    </div>
  )
}

export default OutcomeManagementPanel
