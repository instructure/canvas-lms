import glob from 'glob'
import {readFile} from 'fs/promises'
import {relative} from 'path'
import {execFileSync} from 'child_process'
import {argv, exit} from 'process'
import {canvasDir, canvasComponents} from '#params'

if (argv.includes('-h') || argv.length < 3) {
  // TODO allow doing some basic reporting/querying by component here
  console.log('Canvas source code to component mapping info')
  console.log('')
  console.log('  -i Check invalid components')
  console.log('  -m Check missing components')
  console.log('  -v List individual components')
  console.log('  -g Report issues to gergich')
  exit(0)
}

const packageJsons = glob.sync(`${canvasDir}/ui/{features,shared}/*/package.json`)

const total = packageJsons.length
const missing = []
const invalid = []

await Promise.all(
  packageJsons.map(async path => {
    const contents = Object.assign(
      {path: relative(canvasDir, path)},
      JSON.parse(await readFile(path))
    )
    if (!contents.canvas || !contents.canvas.component) {
      missing.push(contents)
    } else if (!canvasComponents.includes(contents.canvas.component)) {
      invalid.push(contents)
    }
  })
)

if (argv.includes('-i')) {
  if (invalid.length > 0) {
    console.error(`Invalid component in ${invalid.length} packages`)

    if (argv.includes('-v')) {
      invalid.forEach(contents => {
        console.error(`  ${contents.name} - ${contents.canvas.component} (${contents.path})`)
      })
    }

    if (argv.includes('-g')) {
      invalid.forEach(contents => {
        execFileSync('gergich', [
          'comment',
          JSON.stringify({
            path: contents.path,
            message: `Unknown canvas component '${contents.canvas.component}'`,
            position: 0,
            severity: 'error',
          }),
        ])
      })
    }
  } else {
    console.log('No invalid components')
  }
}

if (argv.includes('-m')) {
  if (missing.length > 0) {
    console.warn(`Missing component for ${missing.length}/${total} packages`)
    if (argv.includes('-v')) {
      missing.forEach(contents => {
        console.warn(`  ${contents.name} (${contents.path})`)
      })
    }

    if (argv.includes('-g')) {
      missing.forEach(contents => {
        execFileSync('gergich', [
          'comment',
          JSON.stringify({
            path: contents.path,
            message: 'No canvas component specifie',
            position: 0,
            // TODO promote to error once we have this added everywhere
            severity: 'warn',
          }),
        ])
      })
    }
  } else {
    console.log('No missing components')
  }
}
