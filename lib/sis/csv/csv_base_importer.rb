#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'csv'

require_dependency 'sis/common'

module SIS
  module CSV
    class CSVBaseImporter
      PARSE_ARGS = {:headers => :first_row,
                  :skip_blanks => true,
                  :header_converters => :downcase,
                  :converters => lambda{|field|field ? field.strip : field}
      }
      def initialize(sis_csv)
        @sis = sis_csv
        @root_account = @sis.root_account
        @batch = @sis.batch
      end

      def process(csv)
        raise NotImplementedError
      end
    
      def logger
        @sis.logger
      end
    
      def add_error(csv, message)
        @sis.add_error(csv, message)
      end
    
      def add_warning(csv, message)
        @sis.add_warning(csv, message)
      end
    
      def update_progress(count = 1)
        @sis.update_progress(count)
      end
    
      def csv_rows(csv)
        ::CSV.foreach(csv[:fullpath], PARSE_ARGS) do |row|
          yield row
        end
      end

      def importer_opts
        { :batch_id => @batch.try(:id),
          :batch_user => @batch.try(:user),
          :logger => @sis.logger,
          :override_sis_stickiness => @sis.override_sis_stickiness,
          :add_sis_stickiness => @sis.add_sis_stickiness,
          :clear_sis_stickiness => @sis.clear_sis_stickiness }
      end
    end
  end
end
