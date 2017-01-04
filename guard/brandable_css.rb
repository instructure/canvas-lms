require 'guard'
require 'guard/plugin'

module Guard
  class BrandableCSS < Plugin
    def start
      @pid = spawn("./node_modules/.bin/brandable_css --watch")
    end

    def stop
      Process.kill(:INT, @pid)
    end
  end
end
