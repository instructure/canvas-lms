!define('jst/quiz/move_question', ['compiled/handlebars_helpers'], function (Handlebars) {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  templates['quiz/move_question'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n<li class=\"list_question\">\n  <input type=\"checkbox\" id=\"list_question_";
  stack1 = helpers.assessment_question || depth0.assessment_question;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.id);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assessment_question.id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" class=\"list_question_checkbox\" name=\"questions[";
  stack1 = helpers.assessment_question || depth0.assessment_question;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.id);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assessment_question.id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" value=\"";
  stack1 = helpers.assessment_question || depth0.assessment_question;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.id);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assessment_question.id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" />\n  <label for=\"list_question_";
  stack1 = helpers.assessment_question || depth0.assessment_question;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.id);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assessment_question.id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\" class=\"list_question_name\">";
  stack1 = helpers.assessment_question || depth0.assessment_question;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.question_data);
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.question_name);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assessment_question.question_data.question_name", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</label>\n  <div class=\"list_question_text\">";
  stack1 = helpers.assessment_question || depth0.assessment_question;
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.question_data);
  stack1 = (stack1 === null || stack1 === undefined || stack1 === false ? stack1 : stack1.question_text);
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "assessment_question.question_data.question_text", { hash: {} }); }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</div>\n</li>\n";
  return buffer;}

  stack1 = helpers.questions || depth0.questions;
  stack2 = helpers.each;
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n";
  return buffer;});
  return templates['quiz/move_question'];
});
