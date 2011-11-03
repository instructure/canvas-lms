!function() { var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['AssignmentDetailsDialog'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, stack3, stack4, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  var buffer = "", stack1, stack2, stack3, stack4;
  buffer += "\n    <div class=\"distribution\" style=\"display: block; \">\n      <div class=\"bar-left\"></div>\n      <div class=\"none-left\" title=\"";
  stack1 = "No one scored lower than %{min}";
  stack2 = "no_one_scored_lower";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\" style=\"width: ";
  stack1 = helpers.noneLeftWidth || depth0.noneLeftWidth;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "noneLeftWidth", { hash: {} }); }
  buffer += escapeExpression(stack1) + "%; left: ";
  stack1 = helpers.noneLeftLeft || depth0.noneLeftLeft;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "noneLeftLeft", { hash: {} }); }
  buffer += escapeExpression(stack1) + "%; \"></div>\n      <div class=\"some-left\" title=\"";
  stack1 = "Scores lower than the average of %{average}";
  stack2 = "scores_lower_than_the_average";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\" style=\"width: ";
  stack1 = helpers.someLeftWidth || depth0.someLeftWidth;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "someLeftWidth", { hash: {} }); }
  buffer += escapeExpression(stack1) + "%; left: ";
  stack1 = helpers.someLeftLeft || depth0.someLeftLeft;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "someLeftLeft", { hash: {} }); }
  buffer += escapeExpression(stack1) + "%; \"></div>\n      <div class=\"some-right\" title=\"";
  stack1 = "Scores higher than the average of %{average}";
  stack2 = "scores_higher_than_the_average";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\" style=\"width: ";
  stack1 = helpers.someRightWidth || depth0.someRightWidth;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "someRightWidth", { hash: {} }); }
  buffer += escapeExpression(stack1) + "%; left: ";
  stack1 = helpers.someRightLeft || depth0.someRightLeft;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "someRightLeft", { hash: {} }); }
  buffer += escapeExpression(stack1) + "%; \"></div>\n      <div class=\"none-right\" title=\"";
  stack1 = "No one scored higher than %{max}";
  stack2 = "no_one_scored_higher";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\" style=\"width: ";
  stack1 = helpers.noneRightWidth || depth0.noneRightWidth;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "noneRightWidth", { hash: {} }); }
  buffer += escapeExpression(stack1) + "%; left: ";
  stack1 = helpers.noneRightLeft || depth0.noneRightLeft;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "noneRightLeft", { hash: {} }); }
  buffer += escapeExpression(stack1) + "%; \"></div>\n      <div class=\"bar-right\"></div>\n    </div>\n  ";
  return buffer;}

  buffer += "<div id=\"assignment-details-dialog\" title=\"";
  stack1 = "Grade statistics for: %{assignment.name}";
  stack2 = "grading_statistics_for_assignment";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\">\n  ";
  stack1 = helpers.showDistribution || depth0.showDistribution;
  stack2 = helpers['if'];
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  <table id=\"assignment-details-dialog-stats-table\">\n    <tr>\n      <th scope=\"row\">";
  stack1 = "Average Score:";
  stack2 = "average_score";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</th>\n      <td>";
  stack1 = helpers.average || depth0.average;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "average", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</td>\n    </tr>\n    <tr>\n      <th scope=\"row\">";
  stack1 = "High Score:";
  stack2 = "high_score";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</th>\n      <td>";
  stack1 = helpers.max || depth0.max;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "max", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</td>\n    </tr>\n    <tr>\n      <th scope=\"row\">";
  stack1 = "Low Score:";
  stack2 = "low_score";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</th>\n      <td>";
  stack1 = helpers.min || depth0.min;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "min", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</td>\n    </tr>\n    <tr>\n      <th scope=\"row\">";
  stack1 = "Total Submitted:";
  stack2 = "total_submitted";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</th>\n      <td>";
  stack1 = "%{cnt} submissions";
  stack2 = "count_of_submissions";
  stack3 = {};
  stack4 = "AssignmentDetailsDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</td>\n    </tr>\n  </table>\n</div>";
  return buffer;}); }();