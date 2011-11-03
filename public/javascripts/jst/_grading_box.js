!function() { var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['_grading_box'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n  <input name=\"default_grade\" type=\"number\" value=\"";
  stack1 = helpers.submission || depth0.submission;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.grade);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "submission.grade", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" class=\"grading_value grading_box\" id=\"student_grading_";
  stack1 = helpers.assignment || depth0.assignment;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.id);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assignment.id", { hash: {} }); }
  buffer += escapeExpression(stack1) + " %>\" style=\"text-align: center; width: 50px;\"/>\n";
  return buffer;}

function program3(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n  <span name=\"default_grade\" class=\"grading_box\" id=\"student_grading_";
  stack1 = helpers.assignment || depth0.assignment;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.id);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assignment.id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\">\n    <input type=\"number\" value=\"";
  stack1 = helpers.submission || depth0.submission;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.grade);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "submission.grade", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" class=\"grading_value\" style=\"text-align: center; width: 50px;\"/>\n    <span style=\"display: none;\">%</span>\n  </span>\n";
  return buffer;}

function program5(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n  <input name=\"default_grade\" type=\"text\" value=\"";
  stack1 = helpers.submission || depth0.submission;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.score);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "submission.score", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" class=\"grading_value grading_box score_value\" id=\"student_grading_";
  stack1 = helpers.assignment || depth0.assignment;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.id);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assignment.id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" style=\"text-align: center; width: 50px;\"/>\n";
  return buffer;}

function program7(depth0,data) {
  
  var buffer = "", stack1, stack2, stack3, stack4;
  buffer += "\n  <select name=\"default_grade\" class=\"grading_value grading_box pass_fail\" id=\"student_grading_<%= assignment.id %>\">\n    <option value=\"\">---</option>\n    <option value=\"complete\">";
  stack1 = "Complete";
  stack2 = "gradebooks.grades.complete";
  stack3 = {};
  stack4 = "grading_box";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</option>\n    <option value=\"incomplete\">";
  stack1 = "Incomplete";
  stack2 = "gradebooks.grades.incomplete";
  stack3 = {};
  stack4 = "grading_box";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</option>\n  </select>\n";
  return buffer;}

function program9(depth0,data) {
  
  var buffer = "", stack1, stack2, stack3, stack4;
  buffer += "\n  <span style=\"font-size: 0.9em;\" >\n    ";
  stack1 = "out of %{assignment.points_possible}";
  stack2 = "out_of_points_possible";
  stack3 = {};
  stack4 = "grading_box";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </span>\n";
  return buffer;}

  stack1 = helpers.assignment_grading_type_is_points || depth0.assignment_grading_type_is_points;
  stack2 = helpers['if'];
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n";
  stack1 = helpers.assignment_grading_type_is_percent || depth0.assignment_grading_type_is_percent;
  stack2 = helpers['if'];
  tmp1 = self.program(3, program3, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n";
  stack1 = helpers.assignment_grading_type_is_letter_grade || depth0.assignment_grading_type_is_letter_grade;
  stack2 = helpers['if'];
  tmp1 = self.program(5, program5, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n";
  stack1 = helpers.assignment_grading_type_is_pass_fail || depth0.assignment_grading_type_is_pass_fail;
  stack2 = helpers['if'];
  tmp1 = self.program(7, program7, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n";
  stack1 = helpers.showPointsPossible || depth0.showPointsPossible;
  stack2 = helpers['if'];
  tmp1 = self.program(9, program9, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n";
  return buffer;}); 
Handlebars.registerPartial('grading_box', templates['_grading_box']);
}();