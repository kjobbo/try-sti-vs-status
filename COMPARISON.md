# STI vs Status Field - Side-by-Side Comparison

This document provides a direct comparison between the STI approach and the status field approach, demonstrating how they differ in structure, implementation, and behavior.

## Table of Contents
1. [Model Structure](#model-structure)
2. [Validations](#validations)
3. [Callbacks & Post-Transition Actions](#callbacks--post-transition-actions)
4. [State Transition Methods](#state-transition-methods)
5. [Querying](#querying)
6. [Key Differences](#key-differences)

---

## Model Structure

### STI Approach (4 files)

**Base Model:** `app/models/review_case.rb`
```ruby
class ReviewCase < ApplicationRecord
  validates :title, presence: true
  validates :reviewed_by, presence: true
  validates :reviewed_at, presence: true

  # State transitions using becomes!
  def approve!(reviewer:)
    new_record = becomes!(ReviewCase::Approved)
    new_record.reviewed_by = reviewer
    new_record.reviewed_at = Time.current
    new_record.save!
    new_record
  end
end
```

**Subtype Models:**
- `app/models/review_case/approved.rb`
- `app/models/review_case/rejected.rb`
- `app/models/review_case/escalated.rb`

Each subtype is a separate class inheriting from `ReviewCase`.

### Status Approach (1 file)

**Single Model:** `app/models/review_case_with_status.rb`
```ruby
class ReviewCaseWithStatus < ApplicationRecord
  enum :status, {
    pending: 'pending',
    approved: 'approved',
    rejected: 'rejected',
    escalated: 'escalated'
  }, default: :pending

  validates :title, presence: true
  validates :reviewed_by, presence: true, if: -> { approved? || rejected? }
  validates :reviewed_at, presence: true, if: -> { approved? || rejected? }

  # State transitions by setting status
  def approve!(reviewer:)
    self.status = :approved
    self.reviewed_by = reviewer
    self.reviewed_at = Time.current
    save!
  end
end
```

All logic is in one class.

---

## Validations

### STI Approach

**Base Class (`review_case.rb`):**
```ruby
validates :title, presence: true
validates :reviewed_by, presence: true
validates :reviewed_at, presence: true
```

**Approved Subtype (`review_case/approved.rb`):**
```ruby
# Inherits reviewed_by and reviewed_at from base
# No additional validations needed
```

**Rejected Subtype (`review_case/rejected.rb`):**
```ruby
# Inherits reviewed_by and reviewed_at from base
validates :rejection_reason, presence: true
```

**Escalated Subtype (`review_case/escalated.rb`):**
```ruby
validates :escalation_reason, presence: true
# Does NOT inherit reviewed_by/reviewed_at (not needed for escalated)
```

✅ **Validations are distributed** - each subtype only defines what's unique to it.

### Status Approach

**Single Class (`review_case_with_status.rb`):**
```ruby
validates :title, presence: true
validates :reviewed_by, presence: true, if: -> { approved? || rejected? }
validates :reviewed_at, presence: true, if: -> { approved? || rejected? }
validates :rejection_reason, presence: true, if: :rejected?
validates :escalation_reason, presence: true, if: :escalated?
```

⚠️ **All validations in one place** with conditionals for each status.

---

## Callbacks & Post-Transition Actions

### STI Approach - Separate Callbacks per Subtype

**Approved (`review_case/approved.rb`):**
```ruby
after_save :execute_post_approval_actions, if: :saved_change_to_type?

private

def execute_post_approval_actions
  puts "\n🎉 Review case approved! Executing post-approval actions...\n"
  send_approval_notifications
  schedule_implementation
end

def send_approval_notifications
  puts "📧 Sending approval notification for: #{title}"
end

def schedule_implementation
  puts "📅 Scheduling implementation for: #{title}"
end
```

**Rejected (`review_case/rejected.rb`):**
```ruby
after_save :execute_post_rejection_actions, if: :saved_change_to_type?

private

def execute_post_rejection_actions
  puts "\n❌ Review case rejected! Executing post-rejection actions...\n"
  send_rejection_notifications
  log_rejection_metrics
  offer_appeal_process
end
```

**Escalated (`review_case/escalated.rb`):**
```ruby
after_save :execute_post_escalation_actions, if: :saved_change_to_type?

private

def execute_post_escalation_actions
  puts "\n🚨 Review case escalated! Executing post-escalation actions...\n"
  alert_management
  schedule_emergency_review
  halt_related_work
  assign_escalation_handler
end
```

✅ **Each subtype has its own callback** - clean separation of concerns.

### Status Approach - One Callback with Conditionals

**Single Callback (`review_case_with_status.rb`):**
```ruby
after_save :execute_post_transition_actions, if: :saved_change_to_status?

private

def execute_post_transition_actions
  case status
  when 'approved'
    puts "\n🎉 Review case approved! Executing post-approval actions...\n"
    send_approval_notifications
    schedule_implementation
  when 'rejected'
    puts "\n❌ Review case rejected! Executing post-rejection actions...\n"
    send_rejection_notifications
    log_rejection_metrics
    offer_appeal_process
  when 'escalated'
    puts "\n🚨 Review case escalated! Executing post-escalation actions...\n"
    alert_management
    schedule_emergency_review
    halt_related_work
    assign_escalation_handler
  end
end

# All action methods defined in same class
def send_approval_notifications; end
def schedule_implementation; end
def send_rejection_notifications; end
def log_rejection_metrics; end
# ... etc
```

⚠️ **One callback with case statement** - all states' logic mixed together.

---

## State Transition Methods

### STI Approach

```ruby
# No transition methods in base class - becomes! is called directly

# Pattern 1: Using subtype helper methods
review = ReviewCase.create!(title: "Test", reviewed_by: "TBD", reviewed_at: Time.current)
approved = review.becomes!(ReviewCase::Approved).approve_by(reviewer: "Alice")
approved.save!  # Triggers Approved subtype's after_save callback
approved.class  # => ReviewCase::Approved

# Pattern 2: Manual attribute setting
review = ReviewCase.create!(title: "Test", reviewed_by: "TBD", reviewed_at: Time.current)
approved = review.becomes!(ReviewCase::Approved)
approved.reviewed_by = "Alice"
approved.reviewed_at = Time.current
approved.save!
approved.class  # => ReviewCase::Approved
```

✅ The record **becomes a different class** - true polymorphism.
✅ **Explicit `becomes!`** in calling code - clear type transition.

### Status Approach

```ruby
# In single class
def approve!(reviewer:)
  self.status = :approved  # Changes status attribute
  self.reviewed_by = reviewer
  self.reviewed_at = Time.current
  save!  # Triggers single callback with case statement
end

# Returns same class with different status
review = ReviewCaseWithStatus.create!(title: "Test")
review.approve!(reviewer: "Alice")
review.class  # => ReviewCaseWithStatus (always the same)
review.status  # => "approved"
```

⚠️ The record **stays the same class** - just an attribute change.

---

## Querying

### STI Approach

```ruby
# Query by class type
ReviewCase::Approved.all              # Only approved cases
ReviewCase::Approved.count            # Count approved
ReviewCase::Rejected.where(...)       # Query rejected with conditions

# Polymorphic queries
ReviewCase.where(type: 'ReviewCase::Approved')
ReviewCase.where.not(type: 'ReviewCase')  # All transitioned cases

# Type checking
review.is_a?(ReviewCase::Approved)    # true/false
review.class.name                     # "ReviewCase::Approved"
```

✅ **Type-safe queries** using actual classes.

### Status Approach

```ruby
# Query by status attribute
ReviewCaseWithStatus.approved          # Enum scope
ReviewCaseWithStatus.rejected          # Enum scope
ReviewCaseWithStatus.where(status: 'approved')

# Status checking
review.approved?                       # Enum helper
review.status                          # "approved"
```

⚠️ **String/attribute-based** queries - no type safety.

---

## Key Differences

| Aspect | STI (type field) | Status (enum field) |
|--------|------------------|---------------------|
| **Files** | 4 files (1 base + 3 subtypes) | 1 file |
| **Classes** | 4 classes (inheritance hierarchy) | 1 class |
| **Polymorphism** | True polymorphism - different classes | Same class, different attribute |
| **Callbacks** | Each subtype has its own | One callback with case/if statements |
| **Validations** | Distributed across subtypes | All in one class with conditionals |
| **Methods** | Each subtype has its own methods | All methods in one class |
| **Type Safety** | Strong - can't call wrong methods | Weak - all methods always available |
| **Extensibility** | Add new file for new state | Modify existing class |
| **Complexity** | Higher - more files, STI knowledge | Lower - simpler mental model |
| **Conditionals** | Minimal - in base class transitions | Many - in validations, callbacks, methods |
| **Testing** | Each subtype tested separately | One class tests all states |
| **Querying** | Class-based (`ReviewCase::Approved.all`) | Scope-based (`ReviewCaseWithStatus.approved`) |

---

## When to Use Each

### Use STI When:
- ✅ States have **significantly different behavior**
- ✅ States require **different validations**
- ✅ You want **strong type safety** (can't call escalated methods on approved records)
- ✅ You expect to **add many new states** over time
- ✅ States might have **different associations** in the future
- ✅ **Separation of concerns** is a priority

### Use Status Field When:
- ✅ States are **simple** and share most behavior
- ✅ **Transitions are frequent** and need to be fast
- ✅ You want **simpler code structure** (everything in one file)
- ✅ States differ only in **a few attributes**
- ✅ You have a **small number of states** that won't grow
- ✅ Team is **unfamiliar with STI**

---

## Example Output Comparison

Both approaches produce identical output when transitioning states:

```
🎉 Review case approved! Executing post-approval actions...
📧 Sending approval notification for: Add Payment Gateway
📅 Scheduling implementation for: Add Payment Gateway
```

But the **implementation path** is different:

**STI:**
```
review.approve!
→ becomes!(ReviewCase::Approved)
→ save!
→ ReviewCase::Approved#execute_post_approval_actions (separate callback)
```

**Status:**
```
review.approve!
→ self.status = :approved
→ save!
→ ReviewCaseWithStatus#execute_post_transition_actions (case statement)
```

---

## Conclusion

Both approaches are valid. **STI excels at separation of concerns** and type safety but requires more files and STI knowledge. **Status fields are simpler** and easier to understand but require more conditional logic and lack type safety.

Choose based on your team's preferences, the complexity of your state machine, and how much the behavior differs between states.
