# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module DataFixup::SetActlContextTypeForCourseLevelToolProxies
  # The ACTL (AccountConfigurationToolLookup) context_type was added with a
  # default of "Account". This DataFixup finds ACTLs for courses that only have
  # a course-level tool installation -- they don't have an account-level tool
  # installation -- so they must be related to a course-level installation.
  # Ambiguous cases -- where there is a course-level and account-level tool
  # installation -- will be left unchanged with a context_type of "Account" --
  # we don't have any way of telling for sure which tool installation they
  # relate to.
  def self.run
    Lti::ProductFamily.find_each do |product_family|
      ProductFamilyFixer.new(product_family).fix!
    end
  end

  class ProductFamilyFixer
    COURSE_CONTEXT_TYPE = "Course"
    ACCOUNT_CONTEXT_TYPE = "Account"

    attr_reader :product_family

    def initialize(product_family)
      @product_family = product_family
    end

    # For each course-level tool installation
    # Does that course have an account-level installation somewhere in its
    # account chain?
    # If not, find the ACTLs for that course and tool product family (product
    # code + vendor code) and set their context_type to "Course"
    def fix!
      course_ids_with_tool = context_ids_with_tool(COURSE_CONTEXT_TYPE)
      course_ids_with_tool.each do |course_id|
        course = Course.find_by(id: course_id)
        next unless course
        next if course.account_chain_ids.any? { |a| account_ids_with_tool.include?(a) }

        change_all_actls_for_course(course_id)
      end
    end

    private

    def account_ids_with_tool
      @account_ids_with_tool ||= Set.new(context_ids_with_tool(ACCOUNT_CONTEXT_TYPE))
    end

    def context_ids_with_tool(context_type)
      Lti::ToolProxy.active.where(
        product_family_id: product_family.id,
        context_type:
      ).pluck(:context_id)
    end

    # Find all ACTLs for this product family for all assignments in the course,
    # and change context_type to "Course"
    def change_all_actls_for_course(course_id)
      Assignment.active.where(context_id: course_id).find_in_batches do |assignments|
        AssignmentConfigurationToolLookup.where(
          assignment: Array(assignments),
          tool_product_code: product_family.product_code,
          tool_vendor_code: product_family.vendor_code
        ).update(context_type: COURSE_CONTEXT_TYPE)
      end
    end
  end
end
