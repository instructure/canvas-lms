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
import $ from 'jquery'
import I18n from 'i18n!assignments'
import './jquery.instructure_misc_plugins'
import 'compiled/jquery.rails_flash_notifications'

var validFileSubmission = function(ext, contentItem) {
  return !ENV.SUBMIT_ASSIGNMENT ||
         !ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS ||
         ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS.length <= 0 ||
         (contentItem.url.match(/\./) && $.inArray(ext, ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS) >= 0);
};

var invalidToolReturn = function(message) {
    $.flashError(I18n.t("The launched tool returned an invalid resource for this assignment"));
    console.log(message);
    return false;
};

export function recordEulaAgreement (querySelector, checked) {
  const inputs = document.querySelectorAll(querySelector)
  for (let i = 0; i < inputs.length; ++i) {
    inputs[i].value = checked ? new Date().getTime() : ''
  }
}

export function submitContentItem (contentItem) {
    if (!contentItem) {
      return false;
    }

    var valid_submission = true;
    if(contentItem['@type'] === 'LtiLinkItem') {
      if($("#submit_online_url_form").length) {
        $("#external_tool_url").val(contentItem.url);
        $("#external_tool_submission_type").val('basic_lti_launch');
        var $link = $("<a/>", {href: contentItem.url}).text(contentItem.text || contentItem.title);
        $("#external_tool_submission_details").empty().append($link).attr('class', 'url_submission');
      } else {
        return invalidToolReturn("this assignment doesn't accept URL submissions");
      }
    } else if(contentItem['@type'] === 'FileItem') {
      if($("#submit_online_upload_form").length) {
        var ext = contentItem.url.split(/\./).pop();

        if (!validFileSubmission(ext, contentItem)) {
          $('#submit_from_external_tool_form button[type=submit]').attr('disabled', true);
          return invalidToolReturn("Invalid submission file type");
        }

        $("#external_tool_url").val(contentItem.url);
        $("#external_tool_submission_type").val('online_url_to_file');
        $("#external_tool_filename").val(contentItem.text);
        var $link = $("<a/>", {href: contentItem.url}).text(contentItem.text);
        $("#external_tool_submission_details").empty().append($link).attr('class', 'file_submission');
      } else {
        return invalidToolReturn("this assignment doesn't accept file submissions");
      }
    } else {
      return invalidToolReturn("return_type must be 'link' or 'file'");
    }

    return true;
  };

export function verifyPledgeIsChecked(checkbox) {
  if(checkbox.length > 0 && !checkbox.attr('checked')) {
    alert(I18n.t('messages.agree_to_pledge', "You must agree to the submission pledge before you can submit this assignment."));
    return false
  }
  return true
}