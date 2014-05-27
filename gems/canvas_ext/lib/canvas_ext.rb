require 'active_support/all'

module CanvasExt
  project_root = File.dirname(File.absolute_path(__FILE__))
  Dir.glob(project_root + '/canvas_ext/*') {|file| require file}
end
