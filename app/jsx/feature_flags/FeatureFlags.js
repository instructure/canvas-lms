/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import axios from 'axios'
import I18n from 'i18n!feature_flags'
import {Text, Spinner} from '@instructure/ui-elements'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-layout'
import {Tooltip} from '@instructure/ui-overlays'
import {IconInfoLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Table} from '@instructure/ui-table'

const {Head, Body, ColHeader, Row, Cell} = Table

export default class FeatureFlags extends React.Component {

  constructor(props) {
    super(props)
    this.state = {
      isLoading: false,
      features: []
    }
  }

  componentWillMount () {
    this.retrieveFlagsConfig()
  }

  retrieveFlagsConfig() {
    this.setState({isLoading: true})
    const url = `/api/v1/accounts/${ window.ENV.ACCOUNT.id}/features`
    axios.get(url)
      .then((response) => this.loadData(response.data))
  }

  loadData (features) {
    this.setState({features, isLoading: false})
  }

  revert = () => {
    const url = `/api/v1/accounts/${ window.ENV.ACCOUNT.id}/features/flags/new_features_ui`
    return axios.put(url, {state: 'off'})
      .then(() => { window.location.reload(true) });
  }

  renderFeatureRows() {
    return this.state.features.map( feature => {
      return (
        <Row key={feature.feature}>
          <Cell>{feature.display_name}</Cell>
          <Cell>
            <Tooltip
              tip={feature.description}
              on={['click', 'hover', 'focus']}
              variant="inverse"
            >
              <Button variant="icon" icon={IconInfoLine}>
                <ScreenReaderContent>{I18n.t('toggle tooltip')}</ScreenReaderContent>
              </Button>
            </Tooltip>
          </Cell>
          <Cell></Cell>
          <Cell></Cell>
          <Cell></Cell>
        </Row>
      )
    })
  }

  render() {
    return (
      <View as="div">
        <View as="div">
          <Text>{I18n.t(
            'This is the new Feature Preview UI. It is currently read-only. To revert to old UI, click the ' +
            'button. This will disable the "New Feature Flags" feature and refresh the page.'
            )}
          </Text>
        </View>
        <Button
          onClick={this.revert}
          margin="small 0"
        >
          {I18n.t('Revert to old UI')}
        </Button>

        <View as="div" width="80%">
          {this.state.isLoading ? <Spinner renderTitle={I18n.t("Loading features")} /> : (
            <Table caption={I18n.t('Feature Preview')} margin="medium 0 0">
              <Head>
                <Row>
                  <ColHeader id="display_name">{I18n.t('Feature')}</ColHeader>
                  <ColHeader id="description">{I18n.t('Info')}</ColHeader>
                  <ColHeader id="expiration">{I18n.t('Preview Removal')}</ColHeader>
                  <ColHeader id="level">{I18n.t('Level')}</ColHeader>
                  <ColHeader id="state">{I18n.t('State')}</ColHeader>
                </Row>
              </Head>
              <Body>
                {this.renderFeatureRows()}
              </Body>
            </Table>
          )}
        </View>
      </View>
    )
  }
}
