require 'guard'
require 'guard/plugin'

module Guard
  class Gulp < Plugin
    def start
      @pid = spawn("./node_modules/.bin/gulp watch")
    end

    def stop
      Process.kill(:INT, @pid)
    end
  end
end
