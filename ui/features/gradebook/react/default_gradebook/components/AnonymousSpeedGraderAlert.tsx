// @ts-nocheck
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {Mask, Overlay} from '@instructure/ui-overlays'

import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('gradebook')

type Props = {
  speedGraderUrl: string
  onClose: () => void
}

type State = {
  isOpen: boolean
}

class AnonymousSpeedGraderAlert extends React.Component<Props, State> {
  openButton: React.LegacyRef<Button>

  cancelButton: React.LegacyRef<Button>

  constructor(props: Props) {
    super(props)

    this.state = {isOpen: false}

    this.open = this.open.bind(this)
    this.close = this.close.bind(this)

    this.openButton = React.createRef()
    this.cancelButton = React.createRef()
  }

  open() {
    this.setState({isOpen: true})
  }

  close() {
    this.setState({isOpen: false})
    this.props.onClose()
  }

  renderAlert() {
    return (
      <Alert open={this.state.isOpen} variant="error">
        <div id="anonymous-speed-grader-alert-container" className="overlay_screen">
          <Grid>
            <Grid.Row>
              <Grid.Col>
                <Text weight="bold">{I18n.t('Anonymous Mode On:')}</Text>

                <br />

                <Text>
                  {I18n.t('Unable to access specific student. Go to assignment in SpeedGrader?')}
                </Text>
              </Grid.Col>
            </Grid.Row>

            <Grid.Row hAlign="end">
              <Grid.Col width="auto">
                <Button ref={this.cancelButton} onClick={this.close}>
                  {I18n.t('Cancel')}
                </Button>

                <Button
                  margin="auto auto auto small"
                  ref={this.openButton}
                  href={this.props.speedGraderUrl}
                  color="primary"
                >
                  {I18n.t('Open SpeedGrader')}
                </Button>
              </Grid.Col>
            </Grid.Row>
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
        shouldReturnFocus={true}
        onDismiss={this.close}
      >
        <Mask fullscreen={true} onClick={this.close}>
          {this.renderAlert()}
        </Mask>
      </Overlay>
    )
  }
}

export default AnonymousSpeedGraderAlert
