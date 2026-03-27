# Fix Job Backlog & Module Completion

## Step 1: Open Rails console

```bash
rails c
```

## Step 2: Kill zombie jobs

```ruby
Delayed::Job.where(id: [2227002, 2304979, 2361840, 2402851, 2498916]).destroy_all
```

## Step 3: Wait 5-10 minutes

The 115 queued jobs will start draining automatically.

## Step 4: Fix a specific student immediately (optional)

Replace `STUDENT_ID` and `COURSE_ID` with actual IDs.

```ruby
student = User.find(STUDENT_ID)
Course.find(COURSE_ID).context_modules.each { |m| m.evaluate_for(student).evaluate! }
```
