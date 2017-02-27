require "active_support"
require "active_record"

module Selinimum
  class Capture
    module AutoloadExtensions
      def require_or_load(file_name, const_path = nil)
        file_path = File.expand_path(file_name).sub(/\.rb\z/, "") # usually these have no extension, but sometimes they do; ActiveSupport::Dependencies.loaded never uses the extension, so we don't either
        relative_path = AutoloadExtensions.app_path_for(file_path)

        # some gems (e.g. switchman) have autoloadable stuff and have
        # entries in the autoload paths. we don't need to cache them,
        # since those files are not in the repo, thus they are
        # irrelevant to selinimization
        return super unless relative_path

        # typically we'll have a const_path (e.g. `FooBar`), unless we
        # got here from a call to `require_dependency`
        const_names = const_path ? [const_path] : loadable_constants_for_path(file_path)
        ret = AutoloadExtensions.cache_constants(file_path, const_names) do
          super
        end
        Selinimum::Capture.log_autoload relative_path
        ret
      end

      class << self
        def extended(_)
          # make a note of which models are already autoloaded, we'll need
          # to reset their reflection classes later
          preloaded_models
        end

        def preloaded_models
          @preloaded_models ||= ActiveRecord::Base.descendants
        end

        CachedAutoload = Struct.new(:const, :ret, :dependencies)

        # if the constant is already in the cache, restore it (and its
        # dependencies). otherwise load it frd (and its dependencies), and
        # put it in the cache so we can restore it later after a reset
        def cache_constants(file_path, const_names)
          autoload_monitor.synchronize do
            ret = nil
            if (cached_autoload = cached_autoloads[file_path])
              restore_constants_for cached_autoload, file_path
              ret = cached_autoload.ret
            else
              dependencies = track_dependencies(const_names) do
                ret = yield
              end

              # we got a const; record it so we can replay it later
              if (const_name = const_names.find { |c| Object.const_defined?(c) })
                const = Object.const_get(const_name)
                cached_autoloads[file_path] = CachedAutoload.new(const, ret, dependencies)
                current_autoloads[file_path] = const
              else
                # this didn't define a const (e.g. we did require_dependency),
                # but its dependencies may have
                if current_dependencies
                  current_dependencies.concat dependencies
                end
              end
            end

            # we're being autoloaded within another file being autoloaded,
            # so we want to let it know it depends on us
            current_dependencies << file_path if current_dependencies

            ret
          end
        end

        # in selenium land, we have a second thread for the rails server,
        # so synchronize autoloading to avoid stomping
        def autoload_monitor
          @autoload_monitor ||= Monitor.new
        end

        def app_path_for(path)
          @root_path ||= Rails.root.to_s + "/"
          return unless path.start_with?(@root_path)
          path = path.sub(@root_path, "")
          path << ".rb" unless path =~ /\.rb\z/
          path
        end

        # whenever we first autoload something, keep track of what it
        # autoloads. returns an array of file paths
        def track_dependencies(const_names)
          dependencies_stack << []
          # when we auto-load something, to really know what it depends on,
          # we need to reset autoloaded stuff, so we don't get freeloaders
          # from a previous autoload. this is true both for top-level
          # autoloads as well as for ones triggered by them.
          #
          # note that we exempt nesting names, since we want to make sure
          # we don't create dummy duplicate modules/classes (either due to
          # redundant definitions, or rails' automatic module-from-
          # directories), e.g.:
          #
          #   # foo/bar/baz.rb
          #   class Foo::Bar # <- we want Baz to be the previously
          #     class Baz    #    autoloaded class, not a new one
          #       ...
          nesting_names = const_names.map { |c| nesting_names_for(c) }.flatten
          temporarily_reset_autoloads(nesting_names) { yield }
          current_dependencies
        ensure
          dependencies_stack.pop
        end

        def nesting_names_for(const_name)
          const_name = const_name.dup
          result = []
          while const_name.sub!(/::[^:]+\z/, "")
            result << const_name.dup
          end
          result
        end

        def dependencies_stack
          @dependencies_stack ||= []
        end

        def current_dependencies
          dependencies_stack.last
        end

        # all autoloaded constants we've captured, ever
        def cached_autoloads
          @cached_autoloads ||= {}
        end

        def loaded_paths
          cached_autoloads.keys.map do |file_path|
            app_path_for(file_path)
          end
        end

        # the currently autoloaded constants (since we last reset)
        def current_autoloads
          @current_autoloads ||= {}
        end

        # bring back this constant and any other ones that were initially
        # autoloaded with it
        def restore_constants_for(cached_autoload, file_path)
          restore_constant(cached_autoload.const, file_path)
          cached_autoload.dependencies.each do |dep|
            next if current_autoloads[dep]
            restore_constants_for(cached_autoloads[dep], dep) if cached_autoloads[dep]
          end
        end

        # bring back a previously autoloaded constant
        def restore_constant(const, file_path)
          parent, _, last = const.name.rpartition("::")
          parent = parent.present? ? Object.const_get(parent) : Object
          parent.const_set(last, const) unless parent.const_defined?(last, false)
          current_autoloads[file_path] = const
        end

        # hide an autoloaded constant so it can be (fake) autoloaded again
        def hide_constant(const, file_path)
          ActiveSupport::Dependencies.loaded.delete file_path
          parent, _, last = const.name.rpartition("::")
          parent = parent.present? ? Object.const_get(parent) : Object
          parent.send :remove_const, last if parent.const_defined?(last, false)
          current_autoloads.delete(file_path)
        end

        # hide any autoloaded constants we know about; this includes ones
        # that were autoloaded this time frd, or that were restored from
        # the cache
        def reset_autoloads!(except = [])
          ActiveSupport::Dependencies::Reference.clear!
          reset_reflection_classes!
          removed_constants = {}
          current_autoloads.keys.reverse_each do |file_path|
            const = current_autoloads[file_path]
            next if except.include?(const.name)
            hide_constant(const, file_path)
            removed_constants[file_path] = const
          end
          removed_constants
        end

        # remove the cached :klass within each reflection of each relevant
        # model
        def reset_reflection_classes!
          classes_to_remove = current_autoloads.values.select { |klass| klass < ActiveRecord::Base }
          classes = preloaded_models + classes_to_remove
          classes_to_remove = Set.new(classes_to_remove)
          classes.each do |klass|
            klass.reflections.each do |_, reflection|
              next unless reflection.instance_variable_get(:@klass)
              next unless classes_to_remove.include?(reflection.klass)
              reflection.remove_instance_variable :@klass
            end
          end
        end

        # temporarily hide any loaded constants, except any whose names
        # match the `except` list
        def temporarily_reset_autoloads(except)
          constants_to_restore = reset_autoloads!(except)
          begin
            yield
          ensure
            current_autoloads.merge! constants_to_restore
            constants_to_restore.each do |file_path, const|
              restore_constant const, file_path
            end
          end
        end
      end
    end
  end
end
