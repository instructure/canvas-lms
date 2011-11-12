!function() { var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['courseList/content'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, stack2, tmp1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;

function program1(depth0,data) {
  
  var buffer = "", stack1, stack2;
  buffer += "\n  <li class=\"customListItem\" data-id=\"";
  stack1 = helpers.id || depth0.id;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "id", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\">\n    <a href=\"";
  stack1 = helpers.href || depth0.href;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "href", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\">\n      <span class=\"name ellipsis\" title=\"";
  stack1 = helpers.longName || depth0.longName;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "longName", { hash: {} }); }
  buffer += escapeExpression(stack1) + "\">";
  stack1 = helpers.shortName || depth0.shortName;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "shortName", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</span>\n      ";
  stack1 = helpers.term || depth0.term;
  stack2 = helpers['if'];
  tmp1 = self.program(2, program2, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n      <span class=\"subtitle ellipsis\">";
  stack1 = helpers.subtitle || depth0.subtitle;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "subtitle", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</span>\n    </a>\n  </li>\n";
  return buffer;}
function program2(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n        <span class=\"subtitle ellipsis enrollment_term menu-item-drop-float-right\">";
  stack1 = helpers.term || depth0.term;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "term", { hash: {} }); }
  buffer += escapeExpression(stack1) + "</span>\n      ";
  return buffer;}

  stack1 = helpers.items || depth0.items;
  stack2 = helpers.each;
  tmp1 = self.program(1, program1, data);
  tmp1.hash = {};
  tmp1.fn = tmp1;
  tmp1.inverse = self.noop;
  stack1 = stack2.call(depth0, stack1, tmp1);
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n";
  return buffer;}); }();