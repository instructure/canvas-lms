/*
this file is just here so we can have it not put componentId in the css
selectors it in the jest snapshots. so we don't get snapshot changes for
random css changes. otherwise, we could just delete this file and have it do
the default
*/
module.exports = {
  generateScopedName: function ({ env }, componentId) { // for css modules class names
    const env2 = process.env.NODE_ENV || env; // because what sets the env arg prefers BABEL_ENV over NODE_ENV
    return (env2 === 'production') ? `${componentId}_[hash:base64:4]` : '[folder]-[name]__[local]';
  }
};
