module.exports = function(config) {
    config.set({
        logLevel: 'LOG_DEBUG',

        reporters: ['spec'],

        singleRun : true,
        autoWatch : false,

        frameworks: [
            'mocha',
            'browserify'
        ],

        files: [
            'test/shims/phantomjs-shims.js',
            'test/*.spec.js'
        ],

        preprocessors: {
            'test/*.spec.js': ['browserify']
        },

        browserify: {
            debug: true
        }
    });
};
