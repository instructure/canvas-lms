module.exports = {
  presets: [
    [
      "@instructure/ui-babel-preset",
      {
        transformImports: false,
        esModules: !(process.env.TRANSPILE || process.env.JEST_WORKER_ID)
      }
    ],
    [
      "@instructure/babel-preset-pretranslated-format-message",
      {
        translationsDir: "locales",
        extractDefaultTranslations: false
      }
    ]
  ]
}