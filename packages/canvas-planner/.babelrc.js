module.exports = {
  "presets": [
    ["@instructure/ui-babel-preset", {
      esModules: !process.env.JEST_WORKER_ID,
      node: !!process.env.JEST_WORKER_ID
    }]
  ],
  "plugins": [
    "inline-react-svg"
  ]
}
