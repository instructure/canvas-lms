start "local_server" /min ruby script/server
start "rails_console" /min cmd /K "ruby script/console"
