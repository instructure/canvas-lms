/* preserve stderr from chrome/etc., so we can know why it fails, e.g.
 *
 *   [7644:7644:0327/202136.818897:ERROR:browser_main_loop.cc(272)] Gtk: cannot open display:
 *
 * this is a bit hacky... karma DI plugin stuff is magical and crazy 'n
 * all, but it doesn't let you override ProcessLauncher stuff (unless you
 * also want to copypasta all of karma-chrome-launcher and more). so
 * just override this one thing before karma proper loads up
 */

const ProcessLauncher = require('karma/lib/launchers/process')
const tempDir = require('karma/lib/temp_dir')
const { spawn } = require('child_process')

ProcessLauncher.decoratorFactory = function (timer) {
  return function (launcher, processKillTimeout) {
    const spawnWithStderrPassthrough = function (command, args = [], options = {}) {
      const newOptions = Object.assign({}, options)
      newOptions.stdio = ['ignore', 'ignore', 'inherit']
      return spawn.call(null, command, args, newOptions)
    }
    ProcessLauncher.call(launcher, spawnWithStderrPassthrough, tempDir, timer, processKillTimeout)
  }
}
