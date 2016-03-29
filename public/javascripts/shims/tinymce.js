// Internally, tinymce builds a core object (which is what's returned
// from a requirement) and also "exposes" several submodules so plugins
// can access them if they need core functionality that isn't in the public
// interface of the library.  Because we don't want to go change this everywhere,
// this shim gets rewritten for tinymce core requirements (in "frontend_build/nonAmdLoader").
// That means we can take the core object and munge it together with the things
// that are already stored underneath "window.tinymce" (yes, tinymce puts them
//  there explicitly regardless of the exports context).  That makes the library
//  at "window.tinymce" look the way some of it's plugins expect for hoisting
// core functions into plugin code.  It's disgusting, I'm sorry, but this is how
// we make a transition without changing app code.  This "realTinymce" thing
// works because we define an alias in webpack.config.js
var assign = require("lodash.underscore").extend;
var tinymceCore = require("realTinymce");
assign(window.tinymce, tinymceCore.tinymce);
module.exports = window.tinymce;
