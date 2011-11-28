!define('jst/courseList/wrapper', ['compiled/handlebars_helpers'], function (Handlebars) {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  templates['courseList/wrapper'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, stack3, stack4, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0;


  buffer += "<div class=\"customListWrapper\">\n  <a class=\"customListClose\" title='";
  stack1 = "close";
  stack2 = "close_course_menu_title";
  stack3 = {};
  stack4 = "courseList.wrapper";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "'></a>\n  <button class=\"button small-button customListRestore\">";
  stack1 = "Reset";
  stack2 = "reset_course_menu";
  stack3 = {};
  stack4 = "courseList.wrapper";
  stack3['scope'] = stack4;
  stack4 = helpers['t'] || depth0['t'];
  tmp1 = {};
  tmp1.hash = stack3;
  if(typeof stack4 === functionType) { stack1 = stack4.call(depth0, stack2, stack1, tmp1); }
  else if(stack4=== undef) { stack1 = helperMissing.call(depth0, "t", stack2, stack1, tmp1); }
  else { stack1 = stack4; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</button>\n  <ul class=\"customListContent menu-item-drop-column-list\"></ul>\n</div>";
  return buffer;});
  return templates['courseList/wrapper'];
});
