/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import I18n from 'i18n!custom_help_link'
import CustomHelpLinkIconInput from './CustomHelpLinkIconInput'
import IconCog from 'jsx/shared/icons/IconCog'
import IconFolder from 'jsx/shared/icons/IconFolder'
import IconInformation from 'jsx/shared/icons/IconInformation'
import IconLifePreserver from 'jsx/shared/icons/IconLifePreserver'
import IconQuestionMark from 'jsx/shared/icons/IconQuestionMark'

  const CustomHelpLinkIcons = React.createClass({
    propTypes: {
      defaultValue: React.PropTypes.string
    },
    render () {
      const {
        defaultValue
      } = this.props
      return (
        <fieldset className="ic-Fieldset ic-Fieldset--radio-checkbox">
          <legend className="ic-Legend">
            { I18n.t('Icon') }
          </legend>
          <div className="ic-Form-control ic-Form-control--radio ic-Form-control--radio-inline">
            <CustomHelpLinkIconInput
              value="help"
              defaultChecked={defaultValue === 'help'}
              label={I18n.t('Question mark icon')}>
              <IconQuestionMark />
            </CustomHelpLinkIconInput>

            <CustomHelpLinkIconInput
              value="information"
              defaultChecked={defaultValue === 'information'}
              label={I18n.t('Information icon')}>
              <IconInformation />
            </CustomHelpLinkIconInput>

            <CustomHelpLinkIconInput
              value="folder"
              defaultChecked={defaultValue === 'folder'}
              label={I18n.t('Folder icon')}>
              <IconFolder />
            </CustomHelpLinkIconInput>

            <CustomHelpLinkIconInput
              value="cog"
              defaultChecked={defaultValue === 'cog'}
              label={I18n.t('Cog icon')}>
              <IconCog />
            </CustomHelpLinkIconInput>

            <CustomHelpLinkIconInput
              value="lifepreserver"
              defaultChecked={defaultValue === 'lifepreserver'}
              label={I18n.t('Life preserver icon')}>
              <IconLifePreserver />
            </CustomHelpLinkIconInput>
          </div>
        </fieldset>
      )
    }
  });

export default CustomHelpLinkIcons
