/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'

import { Alert } from '@instructure/ui-alerts'
import View from '@instructure/ui-layout/lib/components/View'
import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup';
import TextInput from '@instructure/ui-forms/lib/components/TextInput';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import { ToggleDetails } from '@instructure/ui-toggle-details';
import Select from '@instructure/ui-forms/lib/components/Select';
import { AccessibleContent } from '@instructure/ui-a11y'
import { capitalizeFirstLetter } from '@instructure/ui-utils'
import difference from 'lodash/difference'
import filter from 'lodash/filter'
import { RadioInputGroup } from '@instructure/ui-forms/lib/components';
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput';

export default class Placements extends React.Component {
  constructor (props) {
    super(props);
    this.state = {
      placements: this.props.placements
    }
  }

  get specialTypes() {
    return ["editor_button"]
  }

  generateToolConfigurationPart = () => {
    return this.state.toolConfiguration
  }

  placements(obj) {
    return obj.map(o => o.placement);
  }

  placement(p) {
    return p.split("_").map(n => capitalizeFirstLetter(n)).join(" ");
  }

  handlePlacementSelect = (_, opts) => {
    const { placements } = this.state;
    const selected = opts.map(o => o.id)
    const removed = difference(this.placements(placements), selected)
    const added = difference(selected, this.placements(placements));
    this.setState({placements: [...filter(placements, p => !removed.includes(p.placement)), ...this.newPlacements(added)]});
  }

  newPlacements(placements) {
    return placements.map(p => {
      return {
        placement: p
      }
    })
  }

  render() {
    const { placements } = this.state;
    const { validPlacements } = this.props;

    return (
      <React.Fragment>
        <Select
          label={I18n.t("Placements")}
          editable
          formatSelectedOption={(tag) => (
            <AccessibleContent alt={I18n.t("Remove %{placement}", {placement: tag.label})}>{tag.label}</AccessibleContent>
          )}
          multiple
          selectedOption={this.placements(placements)}
          onChange={this.handlePlacementSelect}
        >
          {
            validPlacements.map(p => {
              return <option value={p} key={p}>{this.placement(p)}</option>
            })
          }
        </Select>
        {
          placements.map(p => {
            return <View as="div" margin="medium 0" key={p.placement}>
              <ToggleDetails
                summary={this.placement(p.placement)}
                fluidWidth
              >
                <View
                  as="div"
                  margin="small"
                >
                  <FormFieldGroup
                    description={<ScreenReaderContent>{I18n.t("Placement Values")}</ScreenReaderContent>}
                  >
                    {
                      this.specialTypes.includes(p.placement)
                        ? <Alert
                            variant="warning"
                            margin="small"
                          >
                            {I18n.t("This placement requires Deep Link support by the vendor. Check with your tool vendor to ensure they support this functionality")}
                          </Alert>
                        : null
                    }
                    <FormFieldGroup
                      description={<ScreenReaderContent>{I18n.t("Request Values")}</ScreenReaderContent>}
                      layout="columns"
                    >
                      <TextInput
                        name={`${p.placement}_target_link_uri`}
                        value={p.icon_url}
                        label={I18n.t("Target Link URI")}
                      />
                      <RadioInputGroup
                        name={`${p.placement}_message_type`}
                        value={p.message_type}
                        description={I18n.t("Select Message Type")}
                        required
                      >
                        <RadioInput
                          value="LtiDeepLinkingRequest"
                          label="LtiDeepLinkingRequest"
                        />
                        <RadioInput
                          value="LtiResourceLinkRequest"
                          label="LtiResourceLinkRequest"
                        />
                      </RadioInputGroup>
                    </FormFieldGroup>
                    <FormFieldGroup
                      description={<ScreenReaderContent>{I18n.t("Label Values")}</ScreenReaderContent>}
                      layout="columns"
                    >
                      <TextInput
                        name={`${p.placement}_icon_url`}
                        value={p.icon_url}
                        label={I18n.t("Icon Url")}
                      />
                      <TextInput
                        name={`${p.placement}_text`}
                        value={p.text}
                        label={I18n.t("Text")}
                      />
                    </FormFieldGroup>
                    <FormFieldGroup
                      description={<ScreenReaderContent>{I18n.t("Display Values")}</ScreenReaderContent>}
                      layout="columns"
                    >
                      <TextInput
                        name={`${p.placement}_selection_height`}
                        value={p.selection_height}
                        label={I18n.t("Selection Height")}
                      />
                      <TextInput
                        name={`${p.placement}_selection_width`}
                        value={p.selection_width}
                        label={I18n.t("Selection Width")}
                      />
                    </FormFieldGroup>
                  </FormFieldGroup>
                </View>
              </ToggleDetails>
            </View>
          })
        }
      </React.Fragment>
    )
  }
}

Placements.propTypes = {
  validPlacements: PropTypes.arrayOf(PropTypes.string).isRequired,
  placements: PropTypes.arrayOf(PropTypes.shape({
    placement: PropTypes.string.isRequired
  }))
}

Placements.defaultProps = {
  placements: [{placement: "account_navigation"}, {placement: "link_selection"}]
}
