# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')
require File.expand_path(File.dirname(__FILE__) + '../../../lti2_course_spec_helper')

describe Importers::ToolProfileImporter do

  describe '#process_migration' do
    context 'no tool profiles' do
      let(:data) { {} }
      let(:migration) { double }

      it 'does nothing' do
        expect { Importers::ToolProfileImporter.process_migration(data, migration) }.not_to raise_error
      end
    end

    context 'malformed tool profile' do
      let(:data) { { "tool_profiles" => [{ 'resource_href' => 'href' }] } }
      let(:migration) { double }

      it 'adds an import warning' do
        expect(migration).to receive(:add_import_warning).with('tool_profile', 'href', instance_of(Importers::MissingRequiredToolProfileValuesError))
        Importers::ToolProfileImporter.process_migration(data, migration)
      end
    end

    context 'with tool profile and no tool proxies' do
      let(:data) { get_import_data('', 'matching_tool_profiles') }
      let(:context) { get_import_context }
      let(:migration) { context.content_migrations.create! }

      it 'adds a warning to the migration' do
        expect(migration).to receive(:add_warning).with("We were unable to find a tool profile match for \"learn abc's\". If you would like to use this tool please install it using the following registration url: https://www.samplelaunch.com/register")
        Importers::ToolProfileImporter.process_migration(data, migration)
      end

      it 'adds a warning to the migration without registration url' do
        data['tool_profiles'].first['meta']['registration_url'] = ''
        expect(migration).to receive(:add_warning).with("We were unable to find a tool profile match for \"learn abc's\".")
        Importers::ToolProfileImporter.process_migration(data, migration)
      end
    end

    context 'with tool profile and different version tool proxies' do
      include_context 'lti2_course_spec_helper'

      let(:data) { get_import_data('', 'nonmatching_tool_profiles') }
      let(:migration) { double(context: course) }

      it 'adds a warning to the migration about finding a different version' do
        tool_proxy # necessary to instantiate tool_proxy
        allow(migration).to receive(:import_object?).with(any_args).and_return(true)
        expect(migration).to receive(:add_warning).with("We found a different version of \"learn abc's\" installed for your course. If this tool fails to work as intended, try reregistering or reinstalling it.")
        Importers::ToolProfileImporter.process_migration(data, migration)
      end

      it 'does nothing' do
        tool_proxy # necessary to instantiate tool_proxy
        allow(migration).to receive(:import_object?).with(any_args).and_return(false)
        expect { Importers::ToolProfileImporter.process_migration(data, migration) }.not_to raise_error
      end
    end

    context 'with tool profile and matching tool proxies' do
      include_context 'lti2_course_spec_helper'

      let(:data) { get_import_data('', 'matching_tool_profiles') }
      let(:migration) { double(context: course) }

      it 'does nothing' do
        tool_proxy # necessary to instantiate tool_proxy
        allow(migration).to receive(:import_object?).with(any_args).and_return(true)
        expect { Importers::ToolProfileImporter.process_migration(data, migration) }.not_to raise_error
      end
    end
  end
end
