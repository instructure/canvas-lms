/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

define(["i18n!foo"], function(I18n) {
  I18n.t("#absolute_key", "Absolute key");
  I18n.t("Inferred key");
  define(["i18n!nested"], function(I18n) {
    I18n.t("relative_key", "Relative key in nested scope");
  });
  I18n.t("relative_key", "Relative key");
});

define(["i18n!bar"], function(I18n) {
  I18n.t("relative_key", "Another relative key");
});
