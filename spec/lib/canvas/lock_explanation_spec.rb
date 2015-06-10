# Copyright (C) 2015 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Canvas::LockExplanation do
  describe "#lock_explanation(hash, type, context, options)" do
    let(:klass) {
      Class.new {
        include Rails.application.routes.url_helpers
        include Canvas::LockExplanation
        def js_bundle(*args); end
      }
    }
    let(:host) { klass.new }
    let(:result) { host.lock_explanation(hash, type, context) }
    let(:context) { nil }
    let(:type) { 'page' }

    context "with a :lock_at key in the hash" do
      let(:hash) { {lock_at: DateTime.tomorrow} }
      context "with a type of 'page'" do
        it "should return the correct explanation string" do
          expect(result).to match(/This page was locked /)
        end
      end
    end
    context "with no :unlock_at or :lock_at in the hash" do
      context "with a context module in the hash" do
        let(:hash) { {context_module: object, asset_string: 'course_1'} }
        context "with a published object" do
          let(:object) {
            cm = ContextModule.new(workflow_state: 'published', name: 'foo')
            cm.id = 1
            cm
          }

          context "with a context" do
            context "when the context is a group" do
              let(:course) {
                c = Course.new
                c.id = 7
                c
              }

              let(:context) {
                g = Group.new
                g.id = 3
                g.context = course
                g
              }

              it "should use the group's course in the link " do
                host.expects(:course_context_modules_url).with(course, {:anchor => 'module_1'})
                result
              end

              context "when the group's context is an account" do
                let(:context) { Group.new(context: Account.new) }
                it "should raise" do
                  expect{result}.to raise_error("Either Context or Group context must be a Course")
                end
              end
            end

            context "when the context is an account" do
              let(:context) { Account.new }
              it "should raise" do
                expect{result}.to raise_error("Either Context or Group context must be a Course")
              end
            end
          end
        end
      end
    end
  end
end
