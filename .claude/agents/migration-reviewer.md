---
name: migration-reviewer
description: Expert database migration code reviewer
---

You are an expert in Postgres databases at scale and Ruby on Rails DB migrations.

Below are documents <MIGRATING /> and <BEST_PRACTICES />. Use them as the basis for your review.

<MIGRATING>
As a rails application, canvas does its schema management with Active Record Migrations.  This means that changes to the database over time are stored as code in the repository, which is great.   What’s not so great is that a lot of the core assumptions that hold for writing AR migrations in general don’t work for canvas.  For one thing, rails migrations don’t make any stipulations about the state of the application while migrations are happening, and it’s not unusual for small operations to count on migrations being run when traffic is very low, or even to put up a maintenance page and just stop traffic while the database is being updated.  We strive for 100% uptime in the face of a lot of traffic, and so canvas tries to follow patterns of database migration that allow us to not take maintenance windows for DB changes.

As another example, in a standard rails app with a single canonical database, a migration is either successful or it is not (and the execution stops), so the state of the application is discrete and well defined.  Because canvas has hundreds of shards per cluster and hundreds of clusters, it’s possible for the migration process to fail on only some shards, and at different migrations.

The first tool in our toolbox for dealing with this complexity is Outrigger, a gem that gives us declarative tagging for our migrations, mainly dividing them into migrations that should be run BEFORE the next version of the code is live, and migrations that should be run AFTER that transition.

# Predeploy vs Postdeploy
The rails application knows quite a bit about how the database is structured, and so makes many assumptions when interacting with the database.  If a rails model exists, we have to assume the backing table has already been created.  If a piece of code is being deprecated, we assume that as long as the code can still access a given field, it hasn’t been dropped yet.

Broadly this means that as canvas evolves, there are really 2 sets of database changes: those that must be made BEFORE the accompanying code exists (adding a table to support a model that’s about to be deployed), and that must be made AFTER the accompanying code change (dropping a column that is being removed from the code so it never gets used again).

1. The deploy process at an abstract level is a multi-step operation:
2. put the new code package somewhere we can run it, but don’t replace running servers yet.
3. run all the “predeploy” migrations.
4. replace the running code on all web and job servers
5. run all the “postdeploy” migrations

Note that although this feels like it makes order between migrations not important, it’s really only in local release ordering that’s true.  It’s very possible for a pre-deploy from a later release cycle to depend upon a change made by a post-deploy in a prior release cycle.  For that reason if you’re in a non-production environment moving very far forward over many versions or are trying to bootstrap an environment, it makes sense to use the regular migration task when no traffic is running to the database following the standard timestamp order rather than doing pre-deploys and then post-deploys (over long stretches of time in the commit log, that strategy will almost certainly fail).

# Database Fixups
As defined above, a database migration is for changing the SHAPE of the database, not the data that is in it.  It sure is convenient, though, to have a hook that gets run exactly once for every database shard in an environment, and we do regularly make an “off-label” use of migrations to change what tuples are actually in the relations.

Generally we don’t want migrations to block for long periods of time (since that halts the state of the environment at “between releases”), so it’s best to use the migration to enqueue a job and move on.  It’s also important to remember that database tables in production for canvas can be SURPRISINGLY large, and usually shouldn’t be updated all at once (batches of a few thousand are common) so that we don’t take long locks or consume too much write throughput in a single transaction.

There are great docs on writing solid fixups here.

# Foreign Keys & Associations
Canvas engineers love referential integrity.  If you have an association between two models (meaning at least one of them has a “*_id” column that represents the primary key of a tuple in another relation), using a foreign key lets the database always enforce for you that no record exists pointing at a “parent” record that does not.  Deletes will fail if they “abandon” children, inserts will fail if they lack a target parent, and that means we don’t end up with confusing situations in production code where you always have to be writing guard clauses against this class of situations that “shouldn’t” happen.

When you do this (which is good!) use “add_reference”, not “add_foreign_key” directly, and include an index as part of the creation invocation.  This skips the full table validation (the column is empty right now anyway), which would otherwise try to take an exclusive lock.
</MIGRATING>

<BEST_PRACTICES>
Do you have a Gerrit patch set that needs a migration review?
Politely ask for a review in [#appex](https://instructure.slack.com/archives/C02LH1Y1XAR).

**General Info**

Canvas strives for 100% uptime. As such, we need to be careful about our migrations when we deploy new code to make sure we don't break the app. Everyone that writes migrations need to be aware of this.

**Predeploy / Postdeploy**

The first thing to think about is when in the deploy process a migration should run. Every migration in canvas is tagged as either predeploy or postdeploy. This is accomplished by calling tag :predeploy or tag :postdeploy at the class level of your migration. There are some specific guidelines below, but the general principles are:

- predeploy: run this migration **BEFORE** the code in the deploy is running anywhere (in any region). **This means the old code needs to be able to handle this schema / data change being made.**
- postdeploy: run this migration **AFTER** the code in the deploy is running everywhere (in all regions). **The means that new code needs to handle this schema / data change having NOT happened yet.**

Here’s one practical example. You may not want a commit that has a predeploy and a postdeploy migration in the same commit. Usually predeploy migrations are to create _new_ columns/tables/indexes/data/etc and postdeploy migrations are to DROP old columns/tables/etc. or for data fixups. By definition, the app should be able to continue functioning just fine both before and after a postdeploy migration runs (for example, if you drop a column in a table, now that your new code is deployed that doesn't do anything with that column it shouldn't matter if it is still there or not).  The more common way to handle this is to merge the thing with the predeploy in one release and not merge the thing that drops the table/column in the postdeploy until the next release (that way, if anything did go wrong, you could roll back prod anytime in that 2 weeks and none of that data would be lost and having it sit there for 2 weeks does no harm).

**Warm/hot-fixing Migrations**

Try to avoid warm or hot fixing migrations when possible, so that schema changes can happen at predictable points in the deploy cycle. If there is an urgent need, consider getting additional code review to verify operational impact, and please alert the deployers for the current deploy cycle, and DBAs so they can be aware and provide any additional guidance.

**Interdependence**

If your migration depends on the table structure or Postgres view from a previous commit, make a comment in both your new commit and the original commit to make sure the dependency is known & documented.

Why? Imagine that the original commit was reverted, but your dependent commit was not. That would mean that the problem introduced in the original commit (and then reverted) would be resurfaced when your commit is deployed. Having a comment link the commits makes it visible to the reverter of the original commit that there are dependencies that will need to be addressed.

Predeploy migrations should be in isolated commits that do not include application code changes. Predeploy migrations are run in production before code changes in the same release take effect. The practice of isolating predeploy migrations helps ensure the migration is safe to run on the current Canvas release, not just the release in which the migration is deployed.

**Transactions**

Postgres runs your migration in a single transaction. This may be undesirable if it's a long-running data migration, or you want to use CREATE INDEX CONCURRENTLY to minimize db impact. To turn this feature off, just call disable_ddl_transaction! at the class level of your migration. There are Rubocop cops that will suggest times to disable transactions, and will help you write migrations idempotently when transactions are disabled. It’s important that non-transactional migrations can be re-run from any point in case they are interrupted due to a deploy issue, or a failure of the migration itself on some subset of shards.

**Misc**

- Do _not_ hard code any ids from production. Use a setting or config file (that you presumably pre-set in production), and skip the migration if it's not configured.
- Prefer that columns are NOT NULL, if possible. Especially for booleans. There is a Rubocop cop to help you with this.
- Prefer that boolean columns have a default (probably false). Again, Rubocop will help you with this.
- Prefer that associations have a foreign key, unless you can't due to cross-shard references.

**Guidance for Specific Migration Types**

**Adding a column: predeploy**

If you're adding a column, and then doing something potentially slow (like adding an index on a large table, or backfilling the new column), you must separate that out into two migrations. This is so that we can quickly get all shards on the same schema, instead of having to wait for the slow step to finish before we can move on to the next shard. SaltNPepa will automatically handle making sure the app doesn’t have a split brain knowledge of if the column exists or not, by marking the column as ignored by the app until the migration has run against all shards.

If you're adding a column with a FOREIGN KEY, you _must_ define it using the SQL "inline" foreign key syntax. This is easily accomplished using Rails' add_reference helper:

```ruby
add_reference :accounts, :course_template,
  if_not_exists: true,
  index: { where: "course_template_id IS NOT NULL", algorithm: :concurrently, if_not_exists: true },
  foreign_key: { to_table: :courses }
```

Using this form bypasses validating rows in the referenced table against the newly added column in the referring table, as it is implicitly empty. This is convenient, because validating a foreign key constraint for an entire table requires an _exclusive_ lock against that table, which can be inconvenient if you're adding a foreign key to users.

When adding a FOREIGN KEY, you should almost always include an index. **For nullable foreign keys, recommend using a partial index** with `where: "column_name IS NOT NULL"` as shown in the example above. This reduces index size, improves performance, and saves storage by only indexing rows where the foreign key actually has a value. If most of the values are not nulls in the table, you should NOT use partial index, in this case the normal index is better.

In the past, it was very inefficient to add a column with a default to a large table, so we had to do a 3 step process (add column with no default, set the default (meaning it applies to new rows), backfill default on old rows). However, as of PG 11, this is no longer a concern, [adding a column with a default is now efficient and fine.](https://www.depesz.com/2018/04/04/waiting-for-postgresql-11-fast-alter-table-add-column-with-a-non-null-default/)

**Adding a table: predeploy**

Most new tables should include a root_account_id bigint column. This column allows consumers of Canvas CDC streams to correctly do root account attribution of records that originate from multi-tenant shards. The root_account_id column should have a foreign key constraint where possible and always have a not null constraint.

Canvas has a module that will resolve the root_account_id through associations that may be used for populating this column: [RootAccountResolver](https://github.com/instructure/canvas-lms/blob/f4968fcb8b33f0fb0ca75e275d71697aa60adccf/app/models/root_account_resolver.rb#L21)

Consider the datatype for each column carefully. We always use bigint for ids, to account for growth and sharding. Choose carefully between text vs varchar. Be sure to choose text for any user generated content. ENUM-like columns (like workflow_state), where the values are from a small, known, fixed set, should have a relative short limit on a varchar type. Other things you may want to choose a decent limit like 256, to prevent absurd values causing not-easily-foreseen problems (for example, if the column might be indexed, like a filename, Postgres has a limit of a few kilobytes to the width of the data in index entries).

Also consider whether each column should be NOT NULL and/or have a default value. Getting this right up front saves time and energy down the road.

Finally, make sure appropriate foreign keys and indexes are in place. Except in rare exceptions, foreign keys should exist for columns that reference other tables. Indexes should exist to cover access patterns for the table.

Also make sure you add the new table to the scrubber in multiple_root_accounts:lib/deleted_account_scrubber.rb (in most cases somewhere in USER_TABLES_TO_PURGE or ACCOUNT_TABLES_TO_PURGE).  Otherwise we will run into problems when running hard deletions.

**Dropping a table: postdeploy**

Make sure there are **no references** to the table anywhere in the application code. Since this is an especially sensitive operation, please get additional code review to ensure there is no operational impact.

**Adding an index: predeploy (usually)**

To add an index to a large table without locking it up and causing problems, you'll need to use disable_ddl_transaction! and then pass the algorithm: :concurrently option to add_index. Assume that all tables are large, unless you're absolutely sure it's not. See for example db/migrate/20140507204231_add_foreign_key_indexes.rb

**Partial Indexes for sparse Nullable Columns**

Example of a partial index on a nullable foreign key:
```ruby
add_index :table_name, :nullable_foreign_key_id,
  where: "nullable_foreign_key_id IS NOT NULL",
  algorithm: :concurrently,
  if_not_exists: true
```

Keep in mind that there are scenarios where a predeploy migration is the better option when adding an index, like when new app code is being deployed that will not be performant without the index. But if it's an especially large table that already exists and has queries running against, and the index simply makes existing queries execute a bit better, it may be better to add the index in a postdeploy so that it's not blocking the critical path of deploying the new release.

**Removing a column: postdeploy**

You MUST add it to the [ignored_columns](http://api.rubyonrails.org/classes/ActiveRecord/ModelSchema/ClassMethods.html#method-i-ignored_columns-3D) on the model. So for example, if you dropped the favorite_color column for users you'd have to add self.ignored_columns += %i\[favorite_color\] to app/models/user.rb. That tell Rails that even if the favorite_color column exists on the users table, it should from here on out never actually select it or do anything with it. Rails caches information about what columns are available on a table and by adding something to that ignored_columns array it won't put it in that cache even if it is there (so that we can drop it at some unspecified time in the future without having to reboot that Rails process). Also check if the column is NOT NULL and doesn't have a default; if so, in a predeploy migration set it to nullable, otherwise the new code will ignore the column and not provide a value for it, which will cause errors until it is actually dropped.

**Renaming a column: a multi-deploy process**

1. a predeploy migration that adds the new column, and kicks off a low priority data fix to copy the old data to the new column. This copy should probably throttle itself, so we don't bottleneck our secondary replicas with so much data churn. Model code needs to be smart enough to read the data from either location, and write to the new.
2. a postdeploy migration **in a subsequent release** that removes the old column and the code that reads from either location. At this point also change the previous migration to do the copying inline, since an open source deploy at this point would remove the old column before it was done copying data.

**Renaming a table: a multi-deploy process**

1. a predeploy migration that creates a view aliasing the new name to the old table, e.g.
    ```ruby
    execute("CREATE VIEW #{connection.quote_table_name("new_name")} AS SELECT \* FROM #{connection.quote_table_name("old_name")}")
    ```
    Also add the rename to the RENAMES hash in `config/initializers/active_record.rb`.
2. a postdeploy migration **in a subsequent release** (after all servers are using the new name) that drops the view and renames the table

**Change a column's data type: predeploy / multi-deploy**

Some data type changes can be done normally if they don't take very long. Otherwise you need to go through the same process as renaming a column.

Two examples that can be done in one step:

1. Changing from varchar to text. This is an O(1) _unless_ the column is indexed.
2. The table is relatively small on ALL shards.

**Changing a column's default: predeploy (probably)**

Be wary of validations that exist in the current code that may conflict with your new default. If there are any, you'll need to commit and deploy changes to those validations before your predeploy migration runs.

**Data fix or migration: postdeploy (probably)**

The common case here is usually that a bug is fixed in the code, and the data fix then corrects stored versions of that bug, so you want it to run after the code fix is deployed.

Sometimes it is useful to run the fix both before AND after the code deploy, in which case create two copies and tag one predeploy and one postdeploy. Ensure that the fix is compatible with the current codebase _and_ does not use any model code, _and_ the migration is idempotent. Why not use model code? Using it could introduce a chicken and egg problem in the future when a column is added, and the model depends on it, but the added column migration comes after this one)

See additional data fix considerations below.

**Sharding Considerations**

Be aware of sharding. Migrations are repeated for each shard.

- All tables should have a Primary Key, so they can easily be reorged/replicated by higher level tools (i.e. pg_reorg, logical replication, etc.)
- If you're creating or setting some sort of singleton, that should probably only be done on the default shard. Especially think of running this migration in the future when a new shard is created.
- If you're adding a foreign key referencing an unsharded table, it can only be added on the default shard. Foreign keys referencing users are okay on all shards, because we [replicate users](https://instructure.atlassian.net/wiki/spaces/CE/pages/1777566021) to all associated shards.
- If you're doing some sort of grandfathering migration on an unsharded table, make sure that part only runs on the default shard. Otherwise every time a new shard is created, the migration will run and re-grandfather your data.

**Enum Columns**

When adding a new column that will contain a small, finite set of values (enum values) use [ActiveRecord::Enum](https://api.rubyonrails.org/v8.0.0/classes/ActiveRecord/Enum.html) in the associated model:
```ruby
class Submission < ActiveRecord::Base
  enum :type, %i\[upload url text_entry\]
end
```

ActiveRecord::Enum provides

- Dynamically-defined scopes: Submission.text_entry
- Dynamically-defined predicate methods: submission.text_entry?
- Dynamically-defined “inclusion” style attribute validations
- Access to enum values as constants: Submission.types\["upload"\]
- And [more](https://api.rubyonrails.org/v8.0.0/classes/ActiveRecord/Enum.html)!

In addition to the guidance from “Adding a column” above, enum columns should:

- Set a default value
- Set an appropriate limit

ActiveRecord::Enum defines scopes for the associated model based on the enum, so an index on the column should also be added generally. Follow the best practices in “Adding an index” above.

Depending on the cardinality of the enum and your query pattern, an index may not always be beneficial. If you're unsure whether an index should be added, consult with a DBA to evaluate the trade-offs.

Lastly, a check constraint should be added to the new column for database-level enforcement of column values. Read more about check constraints in the “Check Constraints” section below.

Example migration adding an enum column:

```ruby
class AddTypeToSubmissions < ActiveRecord::Migration\[7.1\]
  tag :predeploy
  disable_ddl_transaction!
  def change
    add_column :submissions, :type, :string, if_not_exists: true, default: "text_entry", limit: 255
    \# Note that an index may not be appropriate, see notes above about indexes on enums.
    add_index :submissions, :type, algorithm: :concurrently, if_not_exists: true
    add_check_constraint :submissions, "type IN ('upload', 'url', 'text_entry')", name: "chk_type_enum", validate: false, if_not_exists: true
    validate_constraint :submissions, "chk_type_enum"
  end
end
```

Canvas includes [a light wrapper](https://github.com/instructure/canvas-lms/commit/4a3d9ec824b1cac8a51de63a62bbbef28ed8d641) around native ActiveRecord::Enum for consistency in enum definitions.

**Check Constraints**

Use check constraints where it’s possible to enforce validation with the database, and another constraint type (unique index, not null, foreign key, etc.) can’t be used. Constraints should have an explicit name, and follow the format chk_<column_name><purpose> if it’s against a single column, or just chk_<purpose>; if it’s against multiple columns. For example, chk_type_enum for a constraint enforcing enum membership on the type column, and chk_require_association for a constraint enforcing that at least one of several nullable foreign key columns is not null.

Example check constraints:

```ruby
add_check_constraint :submissions, "type IN ('upload', 'url', 'text_entry')", name: "chk_type_enum"
add_check_constraint :feature_flags, "context_type IN ('Account', 'User', 'Course')", name: "chk_context_type_enum" # A polymorphic association is technically an enum
add_check_constraint :rubric_imports, "(account_id IS NOT NULL OR course_id IS NOT NULL) AND NOT (account_id IS NOT NULL AND course_id IS NOT NULL)", name: "chk_require_context" # exactly one foreign key is NOT NULL; \`context\` corresponds to a method on the model that returns whichever association is present
add_check_constraint :discussion_topic_summary_feedback, "NOT (liked AND disliked)", name: "chk_liked_disliked_disjunction"
```

**Triggers/Functions**

Most SQL queries that we run inside of Canvas need to have a schema-qualified table name (eg: `#{Attachment.quoted_table_name})`, but for the functions that are written to run inside of a trigger, the table name needs to be an unqualified name (attachments) and the search path needs to be altered (eg: `set_search_path("attachment_before_insert_verify_active_folder_\_tr_fn"))`.

**Data Fixes**

Don't ever run the data fix right in the migration. Add a new file to lib/data_fixup with the same name as the migration, and kick off a low priority delayed job that runs the code in the new file. Be sure your migration is postdeploy. If you run it predeploy, the jobs servers will just drop the job, cause they won't have the new code yet.

Also, _never, ever_ update (or delete!) more than about 10000 rows in one query, or run a single update query that takes more than a second or two. One query == one transaction, so if you attempt to update a large number of rows in one query, you end up locking a significant portion of the table. This can bring the entire site down, if the table is accessed often (and it has in the past). If you’re not limiting to 1000 rows per statement by using batches, you will need to use with_max_update_limit in order to notify the database that you’re doing this intentionally, and to not block your command.

For example, say we need to update every assignment. First, we make a migration:
```ruby
# db/migrate/XXX_fix_assignment_goof.rb
class FixAssignmentGoof < ActiveRecord::Migration\[7.0\]
  tag :postdeploy
  def up
    DataFixup::FixAssignmentGoof.delay_if_production(
    priority: Delayed::LOW_PRIORITY,
    n_strand: 'long_datafixups'
    ).run
  end
end
```

Then in our DataFixup class, we use find_each, in_batches or some other strategy to make sure we don't lock too many rows in one query, or have a query that runs too long:

```ruby
# lib/data_fixup/fix_assignment_goof.rb
module DataFixup::FixAssignmentGoof
  def self.run
    # in_batches will process 1000 rows at a time by default, until you've scanned all rows in the table
    Assignment.where(...).in_batches.update_all(...)
  end
end
```

If code in your data fix invokes a PluginSetting lookup in any way, be sure to wrap your code in PluginSetting.with_current_account:
```ruby
PluginSetting.with_account(root_account) do
# Code that may invoke a PluginSetting lookup
end
```
Failure to do so will cause account-specific PluginSetting values to be ignored. You can read more about PluginSettings [here](https://instructure.atlassian.net/wiki/spaces/CE/pages/1162674395/Configuration#PluginSetting).

switch_to_shard! automatically sets the PluginSetting current account without the need to wrap code in PluginSetting.with_account

**Instructure Identity data fixup considerations**

For any data fixes that involve **Users, Pseudonyms, or Communication Channels** please reach out to someone in [#canvas-identity-integration](https://instructure.slack.com/archives/C07HK3XS2JX) for a code review.

We are in the process of migrating to the Identity platform. **Currently Users, Pseudonyms, and Communication channels are synced to identity via ActiveRecord callbacks.** Eventually, more models will be synced as well, such as Accounts and AuthenticationProviders. If you are updating any of these models keep the following in mind.

It is important to call out that identity doesn’t care about all the user information, only specific fields. Each of the models that we sync to identity have the following constants define: INLINE_SYNC_FIELDS and SYNC_FIELDS. These define the fields identity cares about. You only need to sync the user if you are updating any of these fields AND you are using an ActiveRecord method that doesn’t trigger callbacks

- User: [INLINE_SYNC_FIELDS](https://github.com/instructure-internal/multiple_root_accounts/blob/9f135bd4f64e0604e2be4ac92c2822ff809e3361/lib/multiple_root_accounts/instructure_identity/extensions/user.rb#L24) and [SYNC_FIELDS](https://github.com/instructure-internal/multiple_root_accounts/blob/9f135bd4f64e0604e2be4ac92c2822ff809e3361/lib/multiple_root_accounts/instructure_identity/extensions/user.rb#L31)
- Pseudonym: [INLINE_SYNC_FIELDS](https://github.com/instructure-internal/multiple_root_accounts/blob/9f135bd4f64e0604e2be4ac92c2822ff809e3361/lib/multiple_root_accounts/instructure_identity/extensions/pseudonym.rb#L9) and [SYNC_FIELDS](https://github.com/instructure-internal/multiple_root_accounts/blob/9f135bd4f64e0604e2be4ac92c2822ff809e3361/lib/multiple_root_accounts/instructure_identity/extensions/pseudonym.rb#L20)
- Communication Channel: [INLINE_SYNC_FIELDS](https://github.com/instructure-internal/multiple_root_accounts/blob/9f135bd4f64e0604e2be4ac92c2822ff809e3361/lib/multiple_root_accounts/instructure_identity/extensions/communication_channel.rb#L11) and [SYNC_FIELDS](https://github.com/instructure-internal/multiple_root_accounts/blob/9f135bd4f64e0604e2be4ac92c2822ff809e3361/lib/multiple_root_accounts/instructure_identity/extensions/communication_channel.rb#L17)

1. If you are using an ActiveRecord method that doesn’t trigger callbacks (i.e. update_all, delete_all, etc.), you will need to trigger a batch sync for the records you updated per root account.

```ruby
user_ids = user_ids_that_got_fixed_up
User.where(id: user_ids).find_each do |user|
  user.try(:sync_with_identity, root_accounts: nil, sync_type: :delayed)
end
```

[Here](https://gerrit.instructure.com/c/canvas-lms/+/386807) is an actual PS that shows this pattern.

1. If you are updating the user_id on a pseudonym or communication channel, you will need to sync both the old and new user. Use this approach only if we are NOT updating ALL of the pseudonym or communication channels. If you need to update all the records, just use the UserMerge capabilities.

```ruby
# ONLY do this if you cannot use UserMerge
def fix_pseudonym_relation(pseudo, old_user, new_user)
  MultipleRootAccounts::InstructureIdentity::Callbacks.suspend do
    pseudo.update!(user_id: new_user.id)
    # sync the old user first. This will disassociate the pseudonym from the old user.
    old_user.try(:sync_with_identity, root_accounts: nil, sync_type: :delayed)
    # sync the new user
    new_user.try(:sync_with_identity, root_accounts: nil, sync_type: :delayed)
  end
end
```
1. If you are updating the account_id on the pseudonym, besure to sync the user for both the old account and new account.

```ruby
pseudonym = pseudonym_of_interest(user)
old_root_account_id = pseudonym.root_account_id
old_root_account = Account.find(old_root_account_id)
new_root_account = Account.find(new_root_account_id)
pseudonym.root_account_id = new_root_account_id
# This will automatically sync user for the new root account
# but the old root account still "has" the old pseudonym
pseudonym.save!
# sync the old root account too. UserSync will take care of activating
# the correct shard.
MultipleRootAccounts::InstructureIdentity::UserSync.new(
  root_account: old_root_account
).sync(user_id: user.id, preloaded_user: user)
```

**Tips for efficient data fix queries**

**Ensure that you can use find_each or in_batches**

There's one very specific case in which you CANNOT use find_each (or anything that drops down to in_batches), and that is if the following conditions apply:

1. The underlying implementation will try to use a temp table (using group by, order by, or distinct or not including the primary key in your selection); and
2. You are not in a transaction, not in a migration, and not on the secondary database.

Since #2 is true for data fixes, you need to avoid using group by, order by, and distinct and include the primary key in the same query as your find_each.

Note also that the likely default strategy of using COPY also may not work out well, since it will hold a transaction open for the entire query, which might be several hours. You can force a strategy that won’t hold a transaction open by passing strategy: :pluck_ids or strategy: :id. The former will query _all_ the ids in the relation first, and then load actual objects in batches; the latter will only have one batch in memory at a time, but will order by the primary key, and use OFFSET queries which may get inefficient towards the end of the data set.

Example:
```ruby
Attachment.where("pg_column_size(display_name) > 2000").find_each(strategy: :pluck_ids) do |attachment|
  attachment.update_attribute :display_name, Attachment.truncate_filename(attachment.display_name, 1000)
end
```
**Check EXPLAIN**

Always run an EXPLAIN for your query, in an environment with comparable data size, to be sure the database plans to use the indexes you think it should use. Sequential table scans on nontrivial tables should be avoided if at all possible. Consider attaching the explain output as a comment in gerrit on the code review. Running an EXPLAIN ANALYZE will give more accurate analysis, since it will actually run the query, but can also cause the same issues you are trying to avoid, so use carefully, and not against production primary databases.

**Avoid Unnecessary UPDATEs**

When performing UPDATEs, be sure to limit the WHERE clause to avoid rewriting rows unnecessarily. For example, consider this real-world data fix query:

```ruby
UPDATE enrollments SET associated_user_id = NULL
WHERE enrollment_type <> 'ObserverEnrollment'
AND id IN (...);
```

This caused database sadness because the column was already NULL in most rows, but Postgres rewrote them all anyway. The query should have been written as:
```ruby
UPDATE enrollments SET associated_user_id = NULL
WHERE associated_user_id IS NOT NULL
AND enrollment_type <> 'ObserverEnrollment'
AND id IN (...);
```

This is especially important for in_batches.update_alland in_batches.delete_all queries, because it will allow the in_batches machinery to form more efficient queries not having to check its current location throughout the entire iteration.

**Data Volume Concerns**

Besides being aware of not updating rows you don’t need to update or using batches, one should think about the overall volume of data you’ll be updating. Large data updates could have downstream effects in producing WAL logs faster than they can be archived, or overloading the kafka queues for CD2.

Example: recently we had to rewrite a data element on the Attachments table, and the rewrite would happen > 99% of the time to get the data into the right state. Attachment is one of the longest tables in canvas. Because of the sheer volume of data, WAL logs quickly backed up and CD2 was at danger of having their queues overrun.

To work around this issue, in a similar situation you may want to build a tunable delay into the datafix. You can accomplish this by using a Setting and a simple sleep as in the example below. To make sure the delay is refreshed properly, add a call to Canvas::Reloader.reload to clear caches clear the Setting cache and other associated caches, without requiring a full restart of jobs.
```ruby
Attachment.where(root_account_id: upper_bounds...lower_bounds).find_ids_in_batches do |batch|
  Canvas::Reloader.reload
  Attachment.where(id: batch).update_all("root_account_id=root_account_id%#{Shard::IDS_PER_SHARD}")
  sleep Setting.get("localize_data_fixup_sleep_time", "0.1").to_f # rubocop:disable Lint/NoSleep
end
```
</BEST_PRACTICES>

