# SimplyVersioned 0.9.3
#
# Simple ActiveRecord versioning
# Copyright (c) 2007,2008 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

module SoftwareHeretics
  
  module ActiveRecord
  
    module SimplyVersioned
      
      class BadOptions < StandardError
        def initialize( keys )
          super( "Keys: #{keys.join( "," )} are not known by SimplyVersioned" )
        end
      end

      DEFAULTS = {
        :keep => nil,
        :automatic => true,
        :exclude => [],
        :explicit => false,
        # callbacks
        :when => nil,
        :on_create => nil,
        :on_update => nil
      }
      
      module ClassMethods
        
        # Marks this ActiveRecord model as being versioned. Calls to +create+ or +save+ will,
        # in future, create a series of associated Version instances that can be accessed via
        # the +versions+ association.
        #
        # Options:
        # +keep+ - specifies the number of old versions to keep (default = nil, never delete old versions)
        # +automatic+ - controls whether versions are created automatically (default = true, save versions)
        # +exclude+ - specify columns that will not be saved (default = [], save all columns)
        #
        # Additional INSTRUCTURE options:
        # +explicit+ - explicit versioning keeps the last version up to date,
        #              but doesn't automatically create new versions (default = false)
        # +when+ - callback to indicate whether an instance needs a version
        #          saved or not. if present, the model is passed to the
        #          callback which should return true or false, true indicating
        #          a version should be saved. if absent, versions are saved if
        #          any attribute other than updated_at is changed.
        # +on_create+ - callback to allow additional changes to a new version
        #               that's about to be saved.
        # +on_update+ - callback to allow additional changes to an updated (see
        #               +explicit+ parameter) version that's about to be saved.
        #
        # To save the record without creating a version either set +versioning_enabled+ to false
        # on the model before calling save or, alternatively, use +without_versioning+ and save
        # the model from its block.
        #
        
        def simply_versioned( options = {} )
          bad_keys = options.keys - SimplyVersioned::DEFAULTS.keys
          raise SimplyVersioned::BadOptions.new( bad_keys ) unless bad_keys.empty?
          
          options.reverse_merge!(DEFAULTS)
          options[:exclude] = Array( options[ :exclude ] ).map( &:to_s )
          
          has_many :versions, :order => 'number DESC', :as => :versionable, :dependent => :destroy, :extend => VersionsProxyMethods
          # INSTRUCTURE: Added to allow quick access to the most recent version
          has_one :current_version, :class_name => 'Version', :order => 'number DESC', :as => :versionable, :dependent => :destroy, :extend => VersionsProxyMethods
          # INSTRUCTURE: Lets us ignore certain things when deciding whether to store a new version
          before_save :check_if_changes_are_worth_versioning
          after_save :simply_versioned_create_version
          
          cattr_accessor :simply_versioned_options
          self.simply_versioned_options = options
          
          class_eval do
            def versioning_enabled=( enabled )
              self.instance_variable_set( :@simply_versioned_enabled, enabled )
            end
            
            def versioning_enabled?
              enabled = self.instance_variable_get( :@simply_versioned_enabled )
              if enabled.nil?
                enabled = self.instance_variable_set( :@simply_versioned_enabled, self.simply_versioned_options[:automatic] )
              end
              enabled
            end
          end
        end

      end

      # Methods that will be defined on the ActiveRecord model being versioned
      module InstanceMethods
        
        # Revert the attributes of this model to their values as of an earlier version.
        #
        # Pass either a Version instance or a version number.
        #
        # options:
        # +except+ specify a list of attributes that are not restored (default: created_at, updated_at)
        #
        def revert_to_version( version, options = {} )
          options.reverse_merge!({
            :except => [:created_at,:updated_at]
          })
          
          version = if version.kind_of?( Version )
            version
          elsif version.kind_of?( Fixnum )
            self.versions.find_by_number( version )
          end
          
          raise "Invalid version (#{version.inspect}) specified!" unless version
          
          options[:except] = options[:except].map( &:to_s )
          
          self.update_attributes( YAML::load( version.yaml ).except( *options[:except] ) )
        end
        
        # Invoke the supplied block passing the receiver as the sole block argument with
        # versioning enabled or disabled depending upon the value of the +enabled+ parameter
        # for the duration of the block.
        def with_versioning( enabled = true)
          versioning_was_enabled = self.versioning_enabled?
          explicit_versioning_was_enabled = @simply_versioned_explicit_enabled
          explicit_enabled = false
          if enabled.is_a?(Hash)
            opts = enabled
            enabled = true
            explicit_enabled = true if opts[:explicit]
          end
          self.versioning_enabled = enabled
          @simply_versioned_explicit_enabled = explicit_enabled
          # INSTRUCTURE: always create a version if explicitly told to do so
          @versioning_explicitly_enabled = enabled == true
          begin
            yield self
          ensure
            @versioning_explicitly_enabled = nil
            self.versioning_enabled = versioning_was_enabled
            @simply_versioned_explicit_enabled = explicit_enabled
          end
        end

        def without_versioning(&block)
          with_versioning(false, &block)
        end
        
        def unversioned?
          self.versions.nil? || self.versions.size == 0
        end
        
        def versioned?
          !unversioned?
        end
        
        # INSTRUCTURE: Added to allow model instances pulled out
        # of versions to still know their version number
        def force_version_number(number)
          @simply_versioned_version_number = number
        end
        attr_accessor :simply_versioned_version_model
  
        def version_number
          if @simply_versioned_version_number
            @simply_versioned_version_number
          elsif self.versions.empty?
            0
          else
            self.versions.current.number
          end
        end

        protected
        
        # INSTRUCTURE: If defined on a method, allow a check
        # on the before_create to see if the changes are worth
        # creating a new version for
        def check_if_changes_are_worth_versioning
          @changes_are_worth_versioning = simply_versioned_options[:when] ?
            simply_versioned_options[:when].call(self) :
            (self.changes.keys - ["updated_at"]).present?
          true
        end
        
        def simply_versioned_create_version
          if self.versioning_enabled?
            # INSTRUCTURE
            if @versioning_explicitly_enabled || @changes_are_worth_versioning
              @changes_are_worth_versioning = nil
              if simply_versioned_options[:explicit] && !@simply_versioned_explicit_enabled && versioned?
                version = self.versions.current
                version.yaml = self.attributes.except( *simply_versioned_options[:exclude] ).to_yaml
                simply_versioned_options[:on_update].try(:call, self, version)
                version.save
              else
                version = self.versions.create( :yaml => self.attributes.except( *simply_versioned_options[:exclude] ).to_yaml )
                if version
                  simply_versioned_options[:on_create].try(:call, self, version)
                  self.versions.clean_old_versions( simply_versioned_options[:keep].to_i ) if simply_versioned_options[:keep]
                end
              end
            end
          end
          true
        end
        
      end

      module VersionsProxyMethods
        
        # Get the Version instance corresponding to this models for the specified version number.
        def get_version( number )
          find_by_number( number )
        end
        alias_method :get, :get_version
        
        # Get the first Version corresponding to this model.
        def first_version
          reorder( 'number ASC' ).first
        end
        alias_method :first, :first_version

        # Get the current Version corresponding to this model.
        def current_version
          reorder( 'number DESC' ).first
        end
        alias_method :current, :current_version
        
        # If the model instance has more versions than the limit specified, delete all excess older versions.
        def clean_old_versions( versions_to_keep )
          where( 'number <= ?', self.maximum( :number ) - versions_to_keep ).each do |version|
            version.destroy
          end
        end
        alias_method :purge, :clean_old_versions
        
        # Return the Version for this model with the next higher version
        def next_version( number )
          reorder( 'number ASC' ).where( "number > ?", number ).first
        end
        alias_method :next, :next_version
        
        # Return the Version for this model with the next lower version
        def previous_version( number )
          reorder( 'number DESC' ).where( "number < ?", number ).first
        end
        alias_method :previous, :previous_version
      end

      def self.included( receiver )
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    
    end
  
  end

end

ActiveRecord::Base.send( :include, SoftwareHeretics::ActiveRecord::SimplyVersioned )
