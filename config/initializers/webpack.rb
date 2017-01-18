if !defined?(CANVAS_WEBPACK)
  webpack_env_var = ENV['USE_WEBPACK']

  if webpack_env_var.present?
    CANVAS_WEBPACK = (webpack_env_var != 'false' && webpack_env_var != 'False')
  else
    webpack_file_path = Rails.root.join('config', "WEBPACK")
    CANVAS_WEBPACK = File.exist?(webpack_file_path)
  end
end
