/**
 * Copyright (C) 2011 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// This module is the recommended way for providing contextual environment data
// from a view to the browser environment.
// Usage like:
// <% js_block do %>
//   require(['ENV'], function(ENV) {
//     ENV.<controllerView> = {
//       contextId: <%= @context.id %>
//     };
//   });
// <% end %>
define('ENV', function() {
  if (typeof(ENV) === "undefined") {
    ENV = {};
  }
  return ENV;
});
