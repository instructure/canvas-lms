/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react';
import { func, string, bool } from 'prop-types';
import I18n from 'i18n!gradebook';
import Button from '@instructure/ui-core/lib/components/Button';
import Popover, { PopoverTrigger, PopoverContent } from '@instructure/ui-core/lib/components/Popover';
import Text from '@instructure/ui-core/lib/components/Text';
import IconDiscussionReplySolid from 'instructure-icons/lib/Solid/IconDiscussionReplySolid';
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent';
import Grid, { GridRow, GridCol } from '@instructure/ui-core/lib/components/Grid';
import ColorPicker from '../../../shared/ColorPicker';
import { statusesTitleMap } from '../../../gradezilla/default_gradebook/constants/statuses';
import { defaultColors } from '../../../gradezilla/default_gradebook/constants/colors';

const colorPickerColors = Object.keys(defaultColors).reduce((obj, key) => {
  obj.push({ hexcode: defaultColors[key], name: key });
  return obj;
}, []);

function formatColor (color) {
  if (color[0] !== '#') {
    return `#${color}`;
  }
  return color;
}

class StatusColorListItem extends React.Component {
  static propTypes = {
    status: string.isRequired,
    color: string.isRequired,
    isColorPickerShown: bool.isRequired,
    colorPickerOnToggle: func.isRequired,
    colorPickerButtonRef: func.isRequired,
    colorPickerContentRef: func.isRequired,
    colorPickerAfterClose: func.isRequired,
    afterSetColor: func.isRequired
  }

  constructor (props) {
    super(props);

    this.state = { color: props.color };
  }

  setColor = (unformattedColor, successFn, errorFn) => {
    const color = formatColor(unformattedColor);
    this.setState({ color }, () => {
      this.props.afterSetColor(color, successFn, errorFn);
    });
  }

  render () {
    const {
      status,
      isColorPickerShown,
      colorPickerOnToggle,
      colorPickerButtonRef,
      colorPickerContentRef,
      colorPickerAfterClose
    } = this.props;

    return (
      <li
        className="Gradebook__StatusModalListItem"
        key={status}
        style={{ backgroundColor: this.state.color }}
      >
        <Grid vAlign="middle">
          <GridRow>
            <GridCol>

              <Text>
                {statusesTitleMap[status]}
              </Text>

            </GridCol>
            <GridCol width="auto">

              <Popover
                on="click"
                show={isColorPickerShown}
                onToggle={colorPickerOnToggle}
                contentRef={colorPickerContentRef}
                applicationElement={() => document.getElementById('application')}
              >
                <PopoverTrigger>

                  <Button
                    buttonRef={colorPickerButtonRef}
                    variant="icon"
                    size="small"
                  >
                    <Text size="medium">
                      <ScreenReaderContent>{I18n.t('%{status} Color Picker', { status })}</ScreenReaderContent>
                      <IconDiscussionReplySolid />
                    </Text>
                  </Button>

                </PopoverTrigger>

                <PopoverContent>

                  <ColorPicker
                    parentComponent="StatusColorListItem"
                    colors={colorPickerColors}
                    currentColor={this.state.color}
                    afterClose={colorPickerAfterClose}
                    hideOnScroll={false}
                    allowWhite
                    nonModal
                    hidePrompt
                    withDarkCheck
                    animate={false}
                    withAnimation={false}
                    withArrow={false}
                    withBorder={false}
                    withBoxShadow={false}
                    setStatusColor={this.setColor}
                  />

                </PopoverContent>
              </Popover>

            </GridCol>
          </GridRow>
        </Grid>
      </li>
    );
  }
}

export default StatusColorListItem;
