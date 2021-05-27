module.exports = {
  "reporterEnabled": "mocha-junit-reporter, spec",
  "mochaJunitReporterReporterOptions": {
    "mochaFile": `${process.env.TEST_RESULT_OUTPUT_DIR}/canvas-rce-junit.xml`,
    "testsuitesTitle": "Canvas RCE Mocha Tests",
    "rootSuiteTitle": "Canvas RCE Mocha Tests"
  }
}
