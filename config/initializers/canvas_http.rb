CanvasHttp.open_timeout = -> { Setting.get('http_open_timeout', 5).to_f }
CanvasHttp.read_timeout = -> { Setting.get('http_read_timeout', 30).to_f }