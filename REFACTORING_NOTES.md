# Refactoring Notes: From Transition Methods to Explicit becomes!

## What Changed

The ReviewCase STI implementation was refactored to make state transitions more explicit and to put the responsibility of setting attributes on the subtypes themselves, rather than in the base class.

## Before (Old Pattern)

### Base Class had transition methods
```ruby
# app/models/review_case.rb
class ReviewCase < ApplicationRecord
  def approve!(reviewer:)
    new_record = becomes!(ReviewCase::Approved)
    new_record.reviewed_by = reviewer
    new_record.reviewed_at = Time.current
    new_record.save!
    new_record
  end

  def reject!(reviewer:, reason:)
    new_record = becomes!(ReviewCase::Rejected)
    new_record.reviewed_by = reviewer
    new_record.reviewed_at = Time.current
    new_record.rejection_reason = reason
    new_record.save!
    new_record
  end
end
```

### Usage
```ruby
review = ReviewCase.create!(title: "Test")
approved = review.approve!(reviewer: "Alice")
```

**Issues with this approach:**
- ❌ `becomes!` is hidden inside the method - not obvious that class changes
- ❌ Base class knows about subtype-specific attributes (coupling)
- ❌ Less flexible - can only set attributes through the method parameters

## After (New Pattern)

### Base Class has NO transition methods
```ruby
# app/models/review_case.rb
class ReviewCase < ApplicationRecord
  # No approve!, reject!, escalate! methods
  # Just shared validations and helper methods
end
```

### Subtypes have attribute setter helpers
```ruby
# app/models/review_case/approved.rb
class ReviewCase::Approved < ReviewCase
  def approve_by(reviewer:)
    self.reviewed_by = reviewer
    self.reviewed_at = Time.current
    self  # Return self for chaining
  end
end

# app/models/review_case/rejected.rb
class ReviewCase::Rejected < ReviewCase
  def reject_by(reviewer:, reason:)
    self.reviewed_by = reviewer
    self.reviewed_at = Time.current
    self.rejection_reason = reason
    self  # Return self for chaining
  end
end

# app/models/review_case/escalated.rb
class ReviewCase::Escalated < ReviewCase
  def escalate_for(reason:)
    self.escalation_reason = reason
    self  # Return self for chaining
  end
end
```

### Usage - Two Patterns Available

**Pattern 1: Using helper methods (concise)**
```ruby
review = ReviewCase.create!(title: "Test", reviewed_by: "TBD", reviewed_at: Time.current)
approved = review.becomes!(ReviewCase::Approved).approve_by(reviewer: "Alice")
approved.save!
```

**Pattern 2: Manual attribute setting (explicit)**
```ruby
review = ReviewCase.create!(title: "Test", reviewed_by: "TBD", reviewed_at: Time.current)
approved = review.becomes!(ReviewCase::Approved)
approved.reviewed_by = "Alice"
approved.reviewed_at = Time.current
approved.save!
```

**Benefits of this approach:**
- ✅ `becomes!` is visible in calling code - clear type transition
- ✅ Base class doesn't know about subtype-specific attributes (decoupled)
- ✅ More flexible - can use helpers or set attributes manually
- ✅ Each subtype is responsible for its own attributes
- ✅ Clearer separation of concerns

## Callbacks Still Work Automatically

Both patterns trigger the automatic post-transition callbacks:

```ruby
approved = review.becomes!(ReviewCase::Approved).approve_by(reviewer: "Alice")
approved.save!

# Output:
# 🎉 Review case approved! Executing post-approval actions...
# 📧 Sending approval notification for: Test
# 📅 Scheduling implementation for: Test
```

The `after_save :execute_post_approval_actions, if: :saved_change_to_type?` callback fires when the type changes, regardless of which pattern you use.

## Why This Is Better

### 1. Explicitness
The type change is now visible in the calling code:
```ruby
# Old: Hidden becomes!
approved = review.approve!(reviewer: "Alice")

# New: Explicit becomes!
approved = review.becomes!(ReviewCase::Approved).approve_by(reviewer: "Alice")
```

### 2. Separation of Concerns
Each subtype knows what it needs:
```ruby
# ReviewCase::Approved knows it needs reviewed_by and reviewed_at
def approve_by(reviewer:)
  self.reviewed_by = reviewer
  self.reviewed_at = Time.current
  self
end

# ReviewCase::Rejected knows it needs those PLUS rejection_reason
def reject_by(reviewer:, reason:)
  self.reviewed_by = reviewer
  self.reviewed_at = Time.current
  self.rejection_reason = reason
  self
end
```

### 3. Flexibility
Developers can choose:
- Use helper methods for common cases
- Set attributes manually for more control
- Mix both approaches

### 4. Less Coupling
The base class doesn't need to know:
- What attributes each subtype requires
- How to set those attributes
- The specific subtype classes (they're passed explicitly)

## Migration Guide

If you have existing code using the old pattern:

**Before:**
```ruby
approved = review.approve!(reviewer: "Alice")
```

**After:**
```ruby
approved = review.becomes!(ReviewCase::Approved).approve_by(reviewer: "Alice")
approved.save!
```

Or:
```ruby
approved = review.becomes!(ReviewCase::Approved)
approved.reviewed_by = "Alice"
approved.reviewed_at = Time.current
approved.save!
```

## Summary

This refactoring makes STI state transitions:
1. More explicit (visible `becomes!`)
2. More flexible (helper methods or manual)
3. Better separated (subtypes own their attributes)
4. Less coupled (base class doesn't know subtype details)

The trade-off is slightly more verbose code, but the benefits in clarity and maintainability are worth it.
