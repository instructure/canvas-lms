!function() { var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['/CustomList/content'] = template(function (Handlebars,depth0,helpers,partials,data) {
  helpers = helpers || Handlebars.helpers;
  var buffer = "", stack1, self=this, functionType="function", helperMissing=helpers.helperMissing, undef=void 0, escapeExpression=this.escapeExpression;


  stack1 = helpers.howdy || depth0.howdy;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "howdy", { hash: {} }); }
  buffer += escapeExpression(stack1) + " ";
  stack1 = helpers.dowdy || depth0.dowdy;
  if(typeof stack1 === functionType) { stack1 = stack1.call(depth0, { hash: {} }); }
  else if(stack1=== undef) { stack1 = helperMissing.call(depth0, "dowdy", { hash: {} }); }
  buffer += escapeExpression(stack1) + " fasdfasfd \n";
  return buffer;}); }()