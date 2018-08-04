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

import $ from 'jquery'
import I18n from 'i18n!gradezilla_uploads'
import 'spin.js/jquery.spin'

export function waitForProcessing(progress) {
  const dfd = $.Deferred();
  const spinner = $("#spinner").spin();

  const amIDoneYet = (currentProgress) => {
    if (currentProgress.workflow_state === "completed") {
      $.ajaxJSON(ENV.uploaded_gradebook_data_path, "GET").then((uploadedGradebook) => {
        spinner.hide();
        dfd.resolve(uploadedGradebook)
      });
    } else if (currentProgress.workflow_state === "failed") {
      dfd.reject(I18n.t("Invalid CSV file. Grades could not be updated."));
    } else {
      setTimeout(() => {
        $.ajaxJSON(`/api/v1/progress/${currentProgress.id}`, "GET")
          .then(amIDoneYet);
      }, 2000);
    }
  }
  amIDoneYet(progress);

  return dfd;
}
