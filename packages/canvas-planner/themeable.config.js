module.exports = {
  generateScopedName: function ({ env }) { // for css modules class names
    const env2 = process.env.NODE_ENV || env; // because what sets the env arg prefers BABEL_ENV over NODE_ENV
    return (env2 === 'production') ? '[hash:base64]' : '[folder]-[name]__[local]';
  }
};
