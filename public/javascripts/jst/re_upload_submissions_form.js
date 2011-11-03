!function() { var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['re_upload_submissions_form'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, stack3, stack4, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0;


  buffer += "<form action=\".\" enctype=\"multipart/form-data\" id=\"re_upload_submissions_form\" method=\"post\" style=\"display: none;\" title=\"";
  stack1 = "Re-Upload Submission Files";
  stack2 = "reupload_submission_files";
  stack3 = {};
  stack4 = "re_upload_submissions_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\">\n  <p>\n    ";
  stack1 = "If you made changes to the student submission files you downloaded before, just zip them back up and upload the zip with the form below. Students will see the modified files in their comments for the submission.";
  stack2 = "upload_info";
  stack3 = {};
  stack4 = "re_upload_submissions_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </p>\n  <p>\n    <i>";
  stack1 = "Make sure you don't change the names of the submission files so we can recognize them.";
  stack2 = "upload_warning";
  stack3 = {};
  stack4 = "re_upload_submissions_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</i>\n  </p>\n  <input type=\"file\" name=\"submissions_zip\"/>\n  <button type=\"submit\" class=\"button\">";
  stack1 = "Upload Files";
  stack2 = "buttons.upload";
  stack3 = {};
  stack4 = "re_upload_submissions_form";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</button>\n</form>\n";
  return buffer;}); }();