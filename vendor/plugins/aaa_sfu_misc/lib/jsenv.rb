ApplicationController.class_eval do
  before_filter :add_node_name_to_jsenv
  def add_node_name_to_jsenv
    appnode = Socket.gethostname().split('.')[0]
    js_env(:APP_NODE => appnode)
  end
end