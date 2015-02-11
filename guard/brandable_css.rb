require 'guard'
require 'guard/guard'

module Guard
  class BrandableCSS < Guard

    def start
      @pid = spawn("./node_modules/.bin/brandable_css --watch")
    end

    def stop
      Process.kill(:INT, @pid)
    end
  end
end
