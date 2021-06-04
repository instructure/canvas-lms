# frozen_string_literal: true

spec = Gem::Specification.find_by_name 'stormbreaker'
Dir.glob(File.join(spec.gem_dir, 'lib', 'stormbreaker', 'tasks', '*')).each { |f| load f }

