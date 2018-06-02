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

function sanitizePlugins(plugins) {
  if (plugins !== undefined) {
    let cleanPlugins = plugins;
    if (typeof plugins === "string") {
      cleanPlugins = plugins.split(",").map(plugin => {
        return plugin.replace(/\s/g, "");
      });
    }
    return cleanPlugins;
  }
  return plugins;
}

const extPluginsToRemove = ["instructure_embed"];

function sanitizeExternalPlugins(external_plugins) {
  if (external_plugins !== undefined) {
    let cleanExternalPlugins = {};
    Object.keys(external_plugins).forEach(key => {
      if (external_plugins.hasOwnProperty(key)) {
        if (extPluginsToRemove.indexOf(key) == -1) {
          cleanExternalPlugins[key] = external_plugins[key];
        }
      }
    });
    return cleanExternalPlugins;
  }
  return external_plugins;
}

function sanitizeEditorOptions(options) {
  let fixed = Object.assign({}, options);

  fixed.plugins = sanitizePlugins(options.plugins);
  fixed.external_plugins = sanitizeExternalPlugins(options.external_plugins);
  fixed.toolbar = options.toolbar;

  return fixed;
}

module.exports = sanitizeEditorOptions;
