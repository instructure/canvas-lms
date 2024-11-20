/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {Outlet} from 'react-router-dom'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Tabs} from '@instructure/ui-tabs'
import {List} from '@instructure/ui-list'
import {Button} from '@instructure/ui-buttons'
import type {LtiDetail} from '../../../../../shared/lti-apps/models/Product'

const I18n = useI18nScope('lti_registrations')
interface LtiDetailModalProps {
  ltiTitle: string
  integrationData: LtiDetail | undefined
  isModalOpen: boolean
  setModalOpen: Function
}

const LtiDetailModal = (props: LtiDetailModalProps) => {
  const [tab, setTab] = useState('placements' as string | undefined)
  const renderPerLtiType =
    props.ltiTitle === 'Learning Tools Interoperability (LTI)® v.1.3 Core Specification'
      ? props.integrationData?.lti_13
      : props.integrationData?.lti_11

  const renderPlacements = () => {
    return renderPerLtiType?.placements.map((placement, i) => {
      const backgroundColor = i % 2 !== 0 ? '#F5F5F5' : '#FFFFFF'
      return (
        <List.Item margin="0">
          <div style={{backgroundColor}}>{placement}</div>
        </List.Item>
      )
    })
  }

  const renderServices = () => {
    return renderPerLtiType?.services.map((service, i) => {
      const backgroundColor = i % 2 !== 0 ? '#F5F5F5' : '#FFFFFF'
      return (
        <List.Item margin="0">
          <div style={{backgroundColor}}>{service}</div>
        </List.Item>
      )
    })
  }

  const renderTabs = () => {
    return (
      <Tabs
        padding="medium"
        variant="secondary"
        onRequestTabChange={(_e: any, {id}: {id?: string | undefined}) => {
          setTab(id)
        }}
      >
        <Tabs.Panel
          id="placements"
          padding="medium 0 0 0"
          isSelected={tab === 'placements'}
          renderTitle={I18n.t('Placements')}
        >
          <Outlet />
          <div style={{border: 'solid', borderWidth: 1, borderRadius: 5, borderColor: '#C7CDD1'}}>
            <List margin="x-small 0 x-small x-small" itemSpacing="small" isUnstyled={true}>
              {renderPlacements()}
            </List>
          </div>
        </Tabs.Panel>
        <Tabs.Panel
          id="services"
          padding="medium 0 0 0"
          isSelected={tab === 'services'}
          active={true}
          renderTitle={I18n.t('Services')}
        >
          <Outlet />
          <div style={{border: 'solid', borderWidth: 1, borderRadius: 5, borderColor: '#C7CDD1'}}>
            <List margin="x-small 0 x-small x-small" itemSpacing="small" isUnstyled={true}>
              {renderServices()}
            </List>
          </div>
        </Tabs.Panel>
        <Tabs.Panel
          id="description"
          padding="medium 0 0 0"
          isSelected={tab === 'description'}
          active={true}
          renderTitle={I18n.t('Description')}
        >
          <Outlet />
          {/* TODO: Determine where description is sourced/if it is present in LP */}
          {/* {props.integrationData?.description}  */}
        </Tabs.Panel>
      </Tabs>
    )
  }

  return (
    <div>
      <Modal
        label={props.ltiTitle}
        open={props.isModalOpen}
        size="large"
        onDismiss={() => props.setModalOpen(false)}
      >
        <Modal.Body>{renderTabs()}</Modal.Body>
        <Modal.Footer>
          <Button onClick={() => props.setModalOpen(false)}>Close</Button>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

export default LtiDetailModal
