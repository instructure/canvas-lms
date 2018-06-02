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
import {func, string} from 'prop-types'
import I18n from 'i18n!gradebook'
import Alert from '@instructure/ui-core/lib/components/Alert'
import Button from '@instructure/ui-core/lib/components/Button'
import Grid, {GridCol, GridRow} from '@instructure/ui-core/lib/components/Grid'
import Mask from '@instructure/ui-core/lib/components/Mask'
import Overlay from '@instructure/ui-core/lib/components/Overlay'
import Text from '@instructure/ui-core/lib/components/Text'

class AnonymousSpeedGraderAlert extends React.Component {
  static propTypes = {
    speedGraderUrl: string.isRequired,
    onClose: func.isRequired
  }

  constructor(props) {
    super(props)

    this.state = {isOpen: false}

    this.open = this.open.bind(this);
    this.close = this.close.bind(this);

    this.bindOpenButton = ref => {
      this.openButton = ref;
    };

    this.bindCancelButton = ref => {
      this.cancelButton = ref;
    };
  }

  open () {
    this.setState({isOpen: true})
  }

  close () {
    this.setState({isOpen: false})
    this.props.onClose();
  }

  renderAlert() {
    return (
      <Alert open={this.state.isOpen} variant="error">
        <div id="anonymous-speed-grader-alert-container" className="overlay_screen">
          <Grid>
            <GridRow>
              <GridCol>
                <Text weight="bold">{I18n.t('Anonymous Mode On:')}</Text>

                <br />

                <Text>
                  {I18n.t('Unable to access specific student. Go to assignment in SpeedGrader?')}
                </Text>
              </GridCol>
            </GridRow>

            <GridRow hAlign="end">
              <GridCol width="auto">
                <Button
                  ref={this.bindCancelButton}
                  onClick={this.close}
                >
                  {I18n.t('Cancel')}
                </Button>

                <Button
                  margin="auto auto auto small"
                  ref={this.bindOpenButton}
                  href={this.props.speedGraderUrl}
                  variant="primary"
                >
                  {I18n.t('Open SpeedGrader')}
                </Button>
              </GridCol>
            </GridRow>
          </Grid>
        </div>
      </Alert>
    )
  }

  render() {
    return (
      <Overlay
        open={this.state.isOpen}
        transition="fade"
        label={I18n.t('Anonymous Mode On')}
        shouldReturnFocus
        onDismiss={this.close}
        applicationElement={() => document.getElementById('application')}
      >
        <Mask fullscreen onClick={this.close}>
          {this.renderAlert()}
        </Mask>
      </Overlay>
    )
  }
}

export default AnonymousSpeedGraderAlert
