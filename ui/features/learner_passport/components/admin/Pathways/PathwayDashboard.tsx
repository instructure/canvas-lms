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

import React, {useCallback} from 'react'
import {useSubmit, useLoaderData, useNavigate} from 'react-router-dom'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconPlusLine} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import AdminHeader from '../AdminHeader'
import PathwayCard from './PathwayCard'
import type {PathwayData} from '../../types'
import {showUnimplemented} from '../../shared/utils'

const PathwaySkelton = () => {
  return <View as="div" width="100%" height="118px" background="secondary" borderRadius="small" />
}

function renderPathwaySkeleton() {
  return (
    <Flex gap="medium" direction="column" margin="medium 0 0 0">
      {['a', 'b', 'c'].map(k => (
        <PathwaySkelton key={k} />
      ))}
    </Flex>
  )
}

const PathwayDashboard = () => {
  const navigate = useNavigate()
  const submit = useSubmit()
  const pathways = (useLoaderData() as PathwayData[]) || []
  const url = new URL(window.location.href)
  if (url.searchParams.has('dupe')) {
    const title = url.searchParams.get('dupe') || 'Pathway'
    showFlashAlert({message: `"${title}" duplicated`, type: 'success'})
    window.history.replaceState(window.history.state, '', url.pathname)
  }
  if (url.searchParams.has('delete')) {
    const title = url.searchParams.get('delete') || 'Pathway'
    showFlashAlert({message: `"${title}" deleted`, type: 'success'})
    window.history.replaceState(window.history.state, '', url.pathname)
  }

  const handleCreateClick = useCallback(() => {
    navigate('../edit/new')
  }, [navigate])

  const handleAction = useCallback(
    (pathwayId: string, action: string) => {
      switch (action) {
        case 'view':
          navigate(`../view/${pathwayId}`)
          break
        case 'edit':
          navigate(`../edit/${pathwayId}`)
          break
        default:
          showUnimplemented({currentTarget: {textContent: action}})
      }
    },
    [navigate]
  )

  return (
    <View as="div" maxWidth="1260px">
      <AdminHeader
        title="Pathways"
        description="Create and manage learning pathways with milestones, requirements, and badges"
      >
        <Button renderIcon={IconPlusLine} color="primary" onClick={handleCreateClick}>
          New Pathway
        </Button>
      </AdminHeader>
      <View as="div" margin="0 large large large">
        {pathways?.length > 0 ? null : (
          <View as="div" margin="0">
            <Text size="medium">No pathways created</Text>
          </View>
        )}
        <View as="div" margin="small 0">
          <Table caption="Pathways">
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="pathway">Pathway</Table.ColHeader>
                <Table.ColHeader id="publish_date">Publish Date</Table.ColHeader>
                <Table.ColHeader id="start_date">Started</Table.ColHeader>
                <Table.ColHeader id="complete_date">Completed</Table.ColHeader>
                <Table.ColHeader id="actions">
                  <ScreenReaderContent>Actions</ScreenReaderContent>
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {pathways && pathways.length > 0
                ? pathways.map(pathway => (
                    <PathwayCard key={pathway.id} pathway={pathway} onAction={handleAction} />
                  ))
                : null}
            </Table.Body>
          </Table>
          {pathways?.length > 0 ? null : renderPathwaySkeleton()}
        </View>
      </View>
    </View>
  )
}

export default PathwayDashboard
