$VERBOSE = nil
Dir["#{Gem.searcher.find('hair_trigger').full_gem_path}/lib/tasks/*.rake"].each { |ext| load ext }
