!define('jst/gradebook_uploads_form', ['compiled/handlebars_helpers'], function (Handlebars) {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  templates['gradebook_uploads_form'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, stack3, stack4, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;


  buffer += "<form action=\"";
  stack1 = helpers.action || depth0.action;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "action", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" enctype=\"multipart/form-data\" id=\"upload_modal\" method=\"post\" title=\"";
  stack1 = "Choose a CSV file to upload";
  stack2 = "titles.upload_form";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\">\n  <input type=\"hidden\" name='authenticity_token' value=\"";
  stack1 = helpers.authenticityToken || depth0.authenticityToken;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "authenticityToken", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\">\n  <style>\n    #gradebook-upload-help {\n      display: none;\n      border: 1px solid #ccc;\n      border-radius: 10px;\n      padding: 10px;\n      margin-bottom: 1.4em;\n      background-color: rgba(0,0,0,0.02);\n    }\n    tr.table-callout-notes td div {\n      padding: 6px;\n      border-radius: 10px;\n      font-weight: bold;\n    }\n    tr.table-callout-notes-spacer td, tr.table-callout-notes td{\n      padding: 0 10px;\n      border: none;\n      background-color: transparent !important;\n      text-align: center;\n      vertical-align: bottom;\n    }\n    .table-callout-notes-spacer span {\n      width: 0;\n      border-style: solid;\n      border-color: #FBD850 transparent;\n      border-width: 15px 15px 0px ;\n      margin: 0 auto;\n      display: block;\n    }\n  </style>\n  <p><a class=\"help\" id=\"gradebook-upload-help-trigger\" href=\"#\">";
  stack1 = "What should the CSV file look like?";
  stack2 = "what_should_csv_look_like";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</a></p>\n  <div id=\"gradebook-upload-help\">\n    <h3 style=\"margin:0\">";
  stack1 = "Example CSV file";
  stack2 = "example_csv_file";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</h3>\n    <table class=\"stylized striped bordered\">\n      <thead>\n        <tr class=\"table-callout-notes\">\n          <td colspan=\"4\"><div class=\"ui-state-active\">";
  stack1 = "You Must have *all* of these columns, you only *need* one per row.";
  stack2 = "explanation_of_required_columns";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = "<em>$1</em>";
  stack3['w0'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</div></td>\n          <td><div class=\"ui-state-active\">";
  stack1 = "Optional, ignored.";
  stack2 = "optional_ignored";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</div></td>\n          <td colspan=\"2\"><div class=\"ui-state-active\">";
  stack1 = "Leaving the ID intact (the \"(581)\" part in this case) will help match better. You can also add new assignments that will be created on the fly.";
  stack2 = "leaving_id_will_match_better_can_add_new_assignment";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</div></td>\n          <td colspan=\"2\"><div class=\"ui-state-active\">";
  stack1 = "Optional, ignored.";
  stack2 = "optional_ignored";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</div></td>\n        </tr>\n        <tr class=\"table-callout-notes-spacer\">\n          <td colspan=\"4\"><span /></td>\n          <td><span /></td>\n          <td colspan=\"2\"><span /></td>\n          <td colspan=\"2\"><span /></td>\n        </tr>\n        <tr>\n          <th>Student</th>\n          <th>ID</th>\n          <th>SIS User ID</th>\n          <th>SIS Login ID</th>\n          <th>Section</th>\n          <th>";
  stack1 = "Existing Assignment (581)";
  stack2 = "existing_assignment_example";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</th>\n          <th>";
  stack1 = "A New Assignment";
  stack2 = "new_assignment_example";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</th>\n          <th>Current Score</th>\n          <th>Final Score</th>\n        </tr>\n      </thead>\n      <tbody>\n        <tr>\n          <td colspan=\"2\">Points Possible</td>\n          <td></td>\n          <td></td>\n          <td></td>\n          <td>50</td>\n          <td>10</td>\n          <td></td>\n          <td></td>\n        </tr>\n        <tr>\n          <td>Smith, John</td>\n          <td>12345</td>\n          <td>2122</td>\n          <td>12321</td>\n          <td>night</td>\n          <td>46</td>\n          <td>8</td>\n          <td></td>\n          <td></td>\n        </tr>\n        <tr>\n          <td>King, Ben</td>\n          <td></td>\n          <td></td>\n          <td></td>\n          <td></td>\n          <td>34</td>\n          <td>60</td>\n          <td></td>\n          <td></td>\n        </tr>\n        <tr>\n          <td></td>\n          <td>12347</td>\n          <td></td>\n          <td></td>\n          <td></td>\n          <td>38</td>\n          <td>3</td>\n          <td></td>\n          <td></td>\n        </tr>\n        <tr>\n          <td></td>\n          <td></td>\n          <td>123</td>\n          <td></td>\n          <td></td>\n          <td>40</td>\n          <td></td>\n          <td></td>\n          <td></td>\n        </tr>\n        <tr>\n          <td></td>\n          <td></td>\n          <td></td>\n          <td>3232</td>\n          <td></td>\n          <td>44</td>\n          <td>7</td>\n          <td></td>\n          <td></td>\n        </tr>\n      </tbody>\n    </table>\n    <p>";
  stack1 = "If in doubt, you can always *download a CSV*, change the grades you want and re-upload the same file.";
  stack2 = "instructions.csv_download_and_upload";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = "<a href=\"%{download_gradebook_csv_url}\">$1</a>";
  stack3['w0'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</p>\n  </div>\n\n  <p style=\"font-size: 1.2em;\">\n    <label for=\"gradebook_upload_uploaded_data\">";
  stack1 = "Choose a CSV file to upload:";
  stack2 = "labels.upload";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</label>\n    <input id=\"gradebook_upload_uploaded_data\" name=\"gradebook_upload[uploaded_data]\" type=\"file\" />\n  </p>\n  \n  <button class=\"button\" type=\"submit\">";
  stack1 = "Upload Data";
  stack2 = "buttons.upload_data";
  stack3 = {};
  stack4 = "gradebook_uploads_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</button>\n</form>\n";
  return buffer;});
  return templates['gradebook_uploads_form'];
});
