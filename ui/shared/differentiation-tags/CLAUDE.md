# Differentiation Tags Feature

## Overview
The Differentiation Tags feature in Canvas LMS provides a robust system for categorizing and managing student groupings within courses. This feature enables instructors to create flexible, reusable tags that can be applied to students for various differentiation purposes including accessibility accommodations, academic levels, learning preferences, or any custom categorization needs.

## Architecture & Implementation

### Technology Stack
- **Frontend**: React 18+ with TypeScript
- **UI Framework**: Instructure UI components
- **State Management**: React Query (TanStack Query)
- **Internationalization**: @canvas/i18n
- **Testing**: Jest & React Testing Library
- **Owner**: EGG team (as indicated in package.json)

### Core Components

#### 1. **DifferentiationTagModalForm** (`DifferentiationTagModalForm.tsx`)
- Main modal interface for creating and editing differentiation tags
- Supports both single and multi-variant tag modes
- Implements bulk management operations
- Enforces variant limits (default: 10 per category)
- Features:
  - Dynamic form validation
  - Duplicate detection
  - Keyboard navigation support
  - Accessible UI patterns

#### 2. **DifferentiationTagTray** (`DifferentiationTagTray/`)
- Side panel interface for browsing and managing tags
- Components:
  - `DifferentiationTagSearch`: Debounced search functionality
  - `TagInfo`: Display component for tag details
  - `DifferentiationTagTrayManager`: State orchestration
- Real-time search and filtering capabilities

#### 3. **PeopleFilter** (`PeopleFilter/PeopleFilter.tsx`)
- Integration point with Canvas People page
- Enables filtering students by tags and roles
- Multi-select dropdown with tag categorization
- MessageBus integration for cross-component communication

#### 4. **UserDifferentiationTagManager**
- User-specific tag management interface
- Handles tag assignment and removal for individual students
- Pagination support for large tag sets

### Data Models

```typescript
interface DifferentiationTagCategory {
  id: number
  name: string
  groups?: DifferentiationTagGroup[]
}

interface DifferentiationTagGroup {
  id: number
  name: string
  members_count: number
}
```

### API Integration

#### Endpoints
- `POST /courses/:course_id/group_categories/bulk_manage_differentiation_tag`
- `POST /courses/:course_id/group_categories/import_tags`
- `GET /courses/:course_id/group_categories/export_tags` (CSV export)

#### React Query Hooks
- `useDifferentiationTagCategoriesIndex`: Fetch all tag categories
- `useBulkManageDifferentiationTags`: Create/update/delete operations
- `useAddTagMembership`: Assign tags to users
- `useDeleteTagMembership`: Remove tag assignments
- `useUserTags`: Fetch user-specific tags

### Key Features

1. **Tag Variants System**
   - Single tags (simple categorization)
   - Multi-variant tags (multiple options within a category)
   - Automatic detection of tag structure

2. **Bulk Operations**
   - Import/export functionality (CSV format)
   - Batch create/update/delete
   - Optimistic updates with rollback on failure

3. **Search & Filter**
   - Real-time search with debouncing
   - Role-based filtering
   - Tag-based student filtering

4. **Accessibility**
   - Screen reader support
   - Keyboard navigation
   - ARIA labels and live regions

5. **Course Conversion Support**
   - Migration tools for legacy grouping systems
   - Conversion job monitoring
   - Progress tracking

### Business Logic & Rules

1. **Variant Limits**: Maximum 10 variants per tag category (configurable)
2. **Naming Constraints**: 
   - Tag names must be unique within a category
   - Special handling for single vs multi-variant naming
3. **Permissions**: Tag management requires appropriate course permissions
4. **Data Integrity**: Cascading deletes for tag categories and groups

### Testing Strategy

#### Frontend Tests (Jest/React Testing Library)
- Component unit tests with React Testing Library
- Hook testing with renderHook patterns
- Mock data utilities in `tagCategoryCardMocks.ts`
- Integration tests for API interactions

#### Selenium/E2E Tests
Primary test files for differentiation tags feature:

**Core Feature Tests:**
- `spec/selenium/people/differentiation_tag_management_spec.rb` - Main E2E test suite
  - Tag creation and editing workflows
  - Single vs multi-variant tag management
  - Permissions and settings validation
  - Import/export functionality
  - Tray and modal interactions

- `spec/selenium/people/user_tagged_modal_spec.rb` - User tag assignment tests
  - User tag viewing
  - Tag assignment/removal workflows
  - Modal interactions

- `spec/selenium/people/people_spec.rb:1096-1140` - People page integration tests
  - Differentiation tags tray context
  - Filter integration

**Integration Tests Across Canvas:**
- `spec/selenium/assignments/assignments_create_edit_assign_to_spec.rb` - Assignment integration
- `spec/selenium/discussions/discussions_edit_page_spec.rb` - Discussion integration
- `spec/selenium/course_wiki_pages/course_wiki_page_create_edit_assign_to_spec.rb` - Wiki page integration
- `spec/selenium/quizzes/quizzes_edit_assign_to_no_tray_spec.rb` - Quiz integration
- `spec/selenium/context_modules_v2/teachers/course_modules2_selective_release_item_assign_to_spec.rb` - Module integration
- `spec/selenium/admin/account_admin_settings_spec.rb` - Admin settings

**Backend/API Tests:**
- `spec/apis/v1/group_categories_api_spec.rb` - API endpoint tests
- `spec/controllers/course_tag_conversion_controller_spec.rb` - Conversion controller tests
- `spec/graphql/loaders/user_loaders/differentiation_tags_loader_spec.rb` - GraphQL loader tests

**SIS Import Tests:**
- `spec/lib/sis/csv/differentiation_tag_membership_importer_spec.rb` - Membership import
- `spec/lib/sis/csv/differentiation_tag_set_importer_spec.rb` - Tag set import
- `spec/lib/sis/csv/differentiation_tag_importer_spec.rb` - Tag import

**Test Helpers:**
- `spec/selenium/helpers/items_assign_to_tray.rb` - Shared test helpers
- `spec/selenium/people/pages/course_people_modal.rb` - Page object model

### Performance Considerations

1. **Query Caching**: 5-minute stale time for tag data
2. **Debounced Search**: 100ms default delay
3. **Pagination**: 40 items per page default
4. **Optimistic Updates**: Immediate UI feedback with rollback

### Development Guidelines

1. **Code Style**: Follow existing React/TypeScript patterns in Canvas
2. **Component Structure**: Keep components focused and composable
3. **State Management**: Use React Query for server state, local state for UI
4. **Testing**: Maintain test coverage for critical paths
5. **Accessibility**: All new features must meet WCAG 2.1 AA standards

### Resources & Documentation

- Instructure UI Components: https://instructure.design
- React Query Documentation: https://tanstack.com/query

## Support & Maintenance

This feature is maintained by the EGG team at Instructure. For questions or issues:
- File bugs in the Canvas LMS issue tracker
- Contact the EGG team via internal channels at #engage