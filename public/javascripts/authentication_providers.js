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
import 'jquery.instructure_misc_helpers'

  var authenticationProviders = {
    hideAllNewAuthTypeForms: function(){
      var newForms = document.querySelectorAll(".auth-form-container--new");
      Array.prototype.forEach.call(newForms, function(el, id){
        el.style.display = "none";
      });
    },

    showFormFor: function(authType){
      var formId = authType + "_form";
      var form =  document.getElementById(formId);
      if(form !== null){
        form.style.display = "";
        setTimeout(function(){
          $(form).find(":focusable:first").focus();
          form.scrollIntoView();
        }, 100);
      }
    },

    hideNoAuthMessage: function(){
      var noAuthMessage = document.getElementById("no_auth");
      if(noAuthMessage !== null){
        noAuthMessage.style.display = "none";
      }
    },

    changedAuthType: function(authType){
      authenticationProviders.hideNoAuthMessage();
      authenticationProviders.hideAllNewAuthTypeForms();
      authenticationProviders.showFormFor(authType);
    }
  };

  export default authenticationProviders;

