ApplicationController.class_eval do
  before_filter :add_node_name_to_jsenv
  def add_node_name_to_jsenv
    appnode = Socket.gethostname().split('.')[0]
    release_dir = File.dirname(__FILE__)
    js_env(:APP_NODE => appnode, :RELEASE => release_dir)
  end
end
