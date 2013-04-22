$VERBOSE = nil

if Gem.respond_to?(:searcher)
  gem_path = Gem.searcher.find('hairtrigger').full_gem_path
else
  gem_path = Gem::Specification.find_by_name('hairtrigger').full_gem_path
end

Dir["#{gem_path}/lib/tasks/*.rake"].each { |ext| load ext }
