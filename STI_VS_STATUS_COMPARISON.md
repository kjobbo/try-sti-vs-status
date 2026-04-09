# STI (type) vs Status Field Comparison

This project demonstrates the difference between using Single Table Inheritance (STI) with a `type` field versus using a simple `status` field for managing state in Rails models.

## Overview

Both approaches solve the same problem: managing different states of a review case. However, they differ significantly in how they organize code and separate concerns.

## STI Approach (ReviewCase with `type` field)

### Files
- `app/models/review_case.rb` - Base class
- `app/models/review_case/approved.rb` - Approved state
- `app/models/review_case/rejected.rb` - Rejected state
- `app/models/review_case/escalated.rb` - Escalated state

### Key Characteristics

**Pros:**
- **Separation of Concerns**: Each state is its own class with its own behavior
- **Polymorphism**: Different classes can have completely different methods and validations
- **Type Safety**: The class itself represents the state
- **Open/Closed Principle**: Adding new states means adding new classes, not modifying existing code
- **Cleaner Queries**: `ReviewCase::Approved.all` vs `ReviewCase.where(status: 'approved')`

**Cons:**
- **More Files**: Each state requires its own file
- **Slightly More Complex**: Understanding STI requires knowledge of inheritance
- **State Transitions**: Uses `becomes!` to change the class type

### Example Usage

```ruby
# Create a review case
review = ReviewCase.create!(title: "Feature Request", description: "Add dark mode",
                           reviewed_by: "TBD", reviewed_at: Time.current)
review.class # => ReviewCase

# Approve it - use becomes! to change the class
approved = review.becomes!(ReviewCase::Approved).approve_by(reviewer: "John")
approved.save!
approved.class # => ReviewCase::Approved
approved.can_reopen? # => true (method only exists on Approved)

# Each subtype has its own validations
ReviewCase::Rejected.create!(title: "Bad", reviewed_by: "Jane")
# => Fails! rejection_reason is required for Rejected

# Query by type
ReviewCase::Approved.count # Only approved reviews
ReviewCase.all # All reviews regardless of type
```

## Status Field Approach (ReviewCaseWithStatus with `status` field)

### Files
- `app/models/review_case_with_status.rb` - Single class with all logic

### Key Characteristics

**Pros:**
- **Simpler Mental Model**: Everything in one class
- **Fewer Files**: All logic in a single file
- **Easier State Transitions**: Just change the status attribute

**Cons:**
- **Conditional Logic Everywhere**: Code is full of `if status == 'approved'` checks
- **Tight Coupling**: All states' logic mixed together
- **Harder to Maintain**: Adding new states means modifying existing class
- **Less Type Safety**: Status is just a string
- **Harder to Test**: Need to test all states in one test file

### Example Usage

```ruby
# Create a review case
review = ReviewCaseWithStatus.create!(title: "Feature Request", status: "pending")
review.class # => ReviewCaseWithStatus

# Approve it - same class, different status
review.approve!(reviewer: "John")
review.class # => ReviewCaseWithStatus (still the same class)
review.status # => "approved"
review.can_reopen? # => true (but method uses conditional: approved?)

# Validations use conditionals
review = ReviewCaseWithStatus.new(title: "Bad", status: "rejected")
review.valid? # => false (rejection_reason required IF rejected)

# Query by status
ReviewCaseWithStatus.where(status: 'approved').count
```

## Side-by-Side Comparison

### Adding New Behavior

**STI Approach:**
```ruby
# app/models/review_case/approved.rb
class ReviewCase::Approved < ReviewCase
  def send_approval_notification
    # Only approved reviews can do this
  end
end
```

**Status Approach:**
```ruby
# app/models/review_case_with_status.rb
def send_approval_notification
  return unless approved? # Need conditional check
  # Implementation
end
```

### Validations

**STI Approach:**
```ruby
# Base class has shared validations
class ReviewCase < ApplicationRecord
  validates :reviewed_by, presence: true, if: -> { approved? || rejected? }
  validates :reviewed_at, presence: true, if: -> { approved? || rejected? }
end

# Subclasses only need their unique validations
class ReviewCase::Rejected < ReviewCase
  validates :rejection_reason, presence: true
end
```

**Status Approach:**
```ruby
# Validations mixed together with conditionals
validates :rejection_reason, presence: true, if: :rejected?
validates :escalation_reason, presence: true, if: :escalated?
validates :reviewed_by, presence: true, if: -> { approved? || rejected? }
```

### Queries

**STI Approach:**
```ruby
ReviewCase::Approved.where(reviewed_by: "John")
ReviewCase::Rejected.count
ReviewCase.where.not(type: "ReviewCase") # All transitioned reviews
```

**Status Approach:**
```ruby
ReviewCaseWithStatus.where(status: "approved", reviewed_by: "John")
ReviewCaseWithStatus.where(status: "rejected").count
ReviewCaseWithStatus.where.not(status: "pending")
```

## When to Use Each Approach

### Use STI When:
- States have significantly different behavior
- States require different validations
- You want strong separation of concerns
- States might have different associations in the future
- You expect to add many new states over time
- Polymorphic behavior is important

### Use Status Field When:
- States are simple and share most behavior
- Transitions are frequent and need to be fast
- You want simpler code structure
- States differ only in a few attributes
- You have a small number of states that won't grow

## Testing the Example

Run the Rails console to test both approaches:

```bash
bin/rails console
```

```ruby
# STI approach
review = ReviewCase.create!(title: "Test", description: "Testing STI")
approved = review.approve!(reviewer: "Alice")
puts approved.class.name # => "ReviewCase::Approved"
puts approved.summary

# Status approach (requires migration)
# review = ReviewCaseWithStatus.create!(title: "Test", status: "pending")
# review.approve!(reviewer: "Alice")
# puts review.class.name # => "ReviewCaseWithStatus" (always the same)
# puts review.summary
```

## Conclusion

Both approaches have their place. **STI with `type`** provides better separation of concerns and is more maintainable for complex state machines with different behaviors. **Status fields** are simpler for basic state tracking where behavior doesn't vary much between states.

In this example, STI shines because:
1. Each state has unique validations
2. Each state has unique behavior methods
3. State transitions change the fundamental nature of the object
4. The code is more maintainable and testable

Choose the approach that best fits your use case!
