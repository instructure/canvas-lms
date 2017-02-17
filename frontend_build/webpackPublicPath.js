module.exports = (process.env.NODE_ENV === 'production') ?
  '/dist/webpack-production/' :
  '/dist/webpack-dev/'
