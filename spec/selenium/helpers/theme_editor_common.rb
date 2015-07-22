require File.expand_path(File.dirname(__FILE__) + '/../common')


def open_theme_editor_with_btn
  fj('.btn.button-sidebar-wide').click
end

def open_theme_editor
  get '/brand_configs/new'
end
