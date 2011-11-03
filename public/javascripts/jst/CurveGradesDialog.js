!function() { var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['CurveGradesDialog'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, stack3, stack4, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  var buffer = "", stack1, stack2, stack3, stack4;
  buffer += "\n      ";
  stack1 = "out of %{assignment.points_possible}";
  stack2 = "out_of_points_possible";
  stack3 = {};
  stack4 = "CurveGradesDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n    ";
  return buffer;}

  buffer += "<form action=\"";
  stack1 = helpers.action || depth0.action;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "action", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" id=\"curve_grade_dialog\" style=\"display: none;\" title=\"";
  stack1 = "Curve Grade for %{assignment.name}";
  stack2 = "curve_grade_for_assignment";
  stack3 = {};
  stack4 = "CurveGradesDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\">\n  <input type=\"hidden\" name=\"_method\" value=\"POST\"/>\n  <input type=\"hidden\" name=\"assignment_id\" class=\"assignment_id\" value=\"";
  stack1 = helpers.assignment || depth0.assignment;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.id);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assignment.id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" />\n  <p>\n    ";
  stack1 = "Enter an average grade for the curve for *%{assignment.name}*. The chart shows a best attempt at curving the grades based on current student scores.";
  stack2 = "curve_average";
  stack3 = {};
  stack4 = "CurveGradesDialog";
  stack3['scope'] = stack4;
  stack4 = "<b>$1</b>";
  stack3['w0'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </p>\n  <div style=\"min-height: 100px;\">\n    <table cellpadding=\"0\" cellspacing=\"0\">\n      <tr id=\"results_list\"></tr>\n      <tr id=\"results_values\"></tr>\n    </table>\n  </div>\n  <p style=\"text-align: center;\">\n    ";
  stack1 = "Average Score";
  stack2 = "average_score";
  stack3 = {};
  stack4 = "CurveGradesDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n    <input type=\"number\" min=\"0\" name=\"middle_score\" id=\"middle_score\" style=\"width: 45px;\" value=\"";
  stack1 = helpers.middle_score || depth0.middle_score;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "middle_score", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\"/>\n    ";
  stack1 = helpers.showOutOf || depth0.showOutOf;
  stack2 = helpers['if'];
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </p>\n  <p>\n    <input type=\"checkbox\" name=\"assign_blanks\" id=\"assign_blanks\"/>\n    <label for=\"assign_blanks\">";
  stack1 = "Assign zeroes to unsubmitted students";
  stack2 = "labels.assign_blanks";
  stack3 = {};
  stack4 = "CurveGradesDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</label>\n  </p>\n  <button data-text-while-loading=\"";
  stack1 = "Curving Grades...";
  stack2 = "buttons.curving_grades";
  stack3 = {};
  stack4 = "CurveGradesDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\" type=\"submit\" class=\"button\">\n    ";
  stack1 = "Curve Grades";
  stack2 = "buttons.curve_grades";
  stack3 = {};
  stack4 = "CurveGradesDialog";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </button>\n</form>\n";
  return buffer;}); }();