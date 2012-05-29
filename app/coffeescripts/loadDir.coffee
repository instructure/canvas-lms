# RequireJS loadDir Plugin
#
# Used to require several files in a directory and returns them in a map, e.g.
#
#  define ['loadDir!some/path file1 file2'], (map) ->
#    # map == {file1: file1, file2: file2}

define
  load: (name, req, load, config) ->
    files = name.replace(/^\s+|\s+$/, '').split(/\s+/)
    path = files.shift()
    req (path + "/" + file for file in files), () ->
      map = {}
      for file, i in files
        map[file.replace(/.*\//, '')] = arguments[i]
      load map
