#encoding:ASCII-8BIT

Rack::Utils.key_space_limit = 128.kilobytes # default is 64KB
Rack::Utils.multipart_part_limit = 256 # default is 128
