#!/usr/bin/env node

const {spawnSync} = require('child_process')

// Filter out --skip-initial-build flag
const args = process.argv.slice(2).filter(arg => arg !== '--skip-initial-build')

// Run tsc with filtered args
const result = spawnSync('tsc', args, {
  stdio: 'inherit',
  shell: true
})

process.exit(result.status)
