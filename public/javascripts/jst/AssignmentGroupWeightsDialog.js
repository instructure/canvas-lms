!function() { var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['AssignmentGroupWeightsDialog'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, stack3, stack4, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0;


  buffer += "<div title=\"";
  stack1 = "Manage assignment group weighting";
  stack2 = "titles.assignment_group_weights";
  stack3 = {};
  stack4 = "AssignmentGroupWeightsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\" style=\"display:none;\" id=\"assignment_group_weights_dialog\">\n  <p style=\"margin-top: 8px;\">\n    <input type=\"checkbox\" id=\"group_weighting_scheme\" name=\"group_weighting_scheme\"/>\n    <label for=\"group_weighting_scheme\">";
  stack1 = "Weight final grade based on groups";
  stack2 = "weight_final";
  stack3 = {};
  stack4 = "AssignmentGroupWeightsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</label>\n  </p>\n  <table>\n    <tbody class=\"groups_holder\">\n      <tr style=\"display:none;\" class=\"assignment_group_row blank\">\n        <th scope=\"row\"><label></label></th>\n        <td><input type=\"number\" min=\"0\" max=\"100\" class=\"group_weight\"/>%</td>\n      </tr>\n    </tbody>\n    <tfoot>\n      <tr>\n        <th>";
  stack1 = "Total";
  stack2 = "titles.total";
  stack3 = {};
  stack4 = "AssignmentGroupWeightsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</th>\n        <td>&nbsp;<span class=\"total_weight\"></span>%</td>\n      </tr>\n    </tfoot>\n  </table>\n  <button class=\"button\" type=\"submit\">";
  stack1 = "Save";
  stack2 = "buttons.save";
  stack3 = {};
  stack4 = "AssignmentGroupWeightsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</button>\n</div>\n";
  return buffer;}); }();