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

import colors from 'jsx/gradezilla/default_gradebook/constants/colors';

const { dark, light } = colors;
const defaults = {
  light: {
    dropped: light.orange,
    excused: light.yellow,
    late: light.blue,
    missing: light.purple,
    resubmitted: light.green
  },
  dark: {
    dropped: dark.orange,
    excused: dark.yellow,
    late: dark.blue,
    missing: dark.purple,
    resubmitted: dark.green
  }
};

// this function makes no accommodations for partially supplied states
function getUserColors (userColors = {}) {
  /* 1. loop and reduce for both light and dark pairs
   * 2. get all keys from userPreferenceColors
   * 3. keep userPreferenceColors keys that are in defaults
   * 4. build a new hash of the filtered pairs of userPreferenceColors
   */
  const filteredColors = ['light', 'dark'].reduce((obj, brightness) => {
    obj[brightness] = Object.keys(userColors) // eslint-disable-line no-param-reassign
      .filter(key => key in defaults[brightness])
      // eslint-disable-next-line no-param-reassign
      .reduce((o, key) => { o[key] = colors[brightness][userColors[key]]; return o; }, {});
    return obj;
  }, { dark: {}, light: {} });

  return {
    dark: {
      ...defaults.dark,
      ...filteredColors.dark
    },
    light: {
      ...defaults.light,
      ...filteredColors.light
    }
  };
}

export default {
  getUserColors
};
