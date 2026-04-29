# Canvas Feature Flags Reference

## Feature Flag Structure
```yaml
feature_name:
  type: setting                    # Always 'setting'
  state: hidden|allowed|allowed_on # Feature state (see below)
  display_name: "Human Name"       # UI display name
  description: "What it does"      # Feature description
  applies_to: RootAccount|Course|SiteAdmin  # Scope level
  shadow: true|false               # Shadow flag (optional)
  root_opt_in: true|false         # Root account opt-in required
  environments:                    # Environment-specific overrides
    development:
      state: allowed_on
    ci:
      state: allowed_on
```

## Feature States
- **`hidden`**: Only visible to site admins; must be explicitly enabled
- **`allowed`**: Available for account admins to toggle on/off
- **`allowed_on`**: Enabled by default; can be toggled off

## Feature Flag Types

### Hidden Feature Flags
- **State**: `state: hidden`
- **Visibility**: Feature must be set by a site admin before it becomes visible to other users
- **Purpose**: Administrative control over when features become available

### Shadow Feature Flags
- **Attribute**: `shadow: true`
- **Visibility**: Only visible to site admin users in API responses
- **Purpose**: Internal/debugging features that shouldn't be exposed in normal UI

### Environment-Specific Flags
- Override global state per environment (development, ci, production)
- Useful for testing features in dev/staging before production

## Usage Patterns

### Ruby/Rails
```ruby
# Check if feature is enabled
@account.feature_enabled?(:feature_name)
@domain_root_account.feature_enabled?(:feature_name)

# In controllers
if @context.account.feature_enabled?(:my_feature)
  # Feature-specific logic
end

# In permissions
account_allows: ->(a) { a.feature_enabled?(:admin_feature) }
```

### JavaScript/TypeScript
```javascript
// Access via ENV object
if (ENV.FEATURES?.feature_name) {
  // Feature-specific code
}

// Check feature in React components
const isFeatureEnabled = ENV.FEATURES?.my_feature || false
```

## Common Files by Team
- `00_standard.yml` - Core platform features
- `tiger_team_release_flags.yml` - Tiger team features
- `app_fundamentals_release_flags.yml` - App fundamentals
- `ams_release_flags.yml` - Account management features
- `engage_release_flags.yml` - Engagement features
- `learning_foundations_release_flags.yml` - Learning features
- `outcomes_feature_flags.yml` - Outcomes features
- `quizzes_release_flags.yml` - Quizzes features

## Best Practices
- Use descriptive feature names (snake_case)
- Start with `state: hidden` for new features
- Include clear display_name and description
- Set appropriate `applies_to` scope
- Use environment overrides for testing
- Consider `root_opt_in` for gradual rollouts

## Applies To Scopes
- **RootAccount**: Feature applies to entire root account and sub-accounts
- **Course**: Feature can be enabled per course
- **SiteAdmin**: Feature only available to site administrators
- **User**: Feature applies to individual users (rare)

## Root Opt-in
- `root_opt_in: true` requires root account to explicitly enable before sub-accounts can use
- `root_opt_in: false` allows sub-accounts to enable independently
- Useful for controlling feature rollout across multi-tenant deployments