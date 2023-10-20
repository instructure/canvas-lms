# frozen_string_literal: true

module Bundler
  module Multilock
    module Ext
      module SourceList
        ::Bundler::SourceList.prepend(self)

        # consider them equivalent if the replacements just have a bunch of dups
        def equivalent_sources?(lock_sources, replacement_sources)
          super(lock_sources, replacement_sources.uniq)
        end
      end
    end
  end
end
