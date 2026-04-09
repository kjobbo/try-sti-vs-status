# ReviewCase Subtype-Specific Actions

This document demonstrates how each STI subtype has completely different post-action workflows and behavior.

## Overview

Each ReviewCase subtype (`Approved`, `Rejected`, `Escalated`) has its own unique set of methods that are **automatically executed** after the state transition via `after_save` callbacks. This showcases STI's ability to separate concerns by giving each class its own behavior without polluting the base class or other subtypes with conditional logic.

## Automatic Execution

When a ReviewCase transitions to a new type (via `approve!`, `reject!`, or `escalate!`), the subtype's `after_save` callback automatically triggers the post-transition actions:

```ruby
# Callbacks defined in each subtype
class ReviewCase::Approved < ReviewCase
  after_save :execute_post_approval_actions, if: :saved_change_to_type?
end

class ReviewCase::Rejected < ReviewCase
  after_save :execute_post_rejection_actions, if: :saved_change_to_type?
end

class ReviewCase::Escalated < ReviewCase
  after_save :execute_post_escalation_actions, if: :saved_change_to_type?
end
```

## ReviewCase::Approved - Post-Approval Actions

After a review case is approved, the following actions are triggered:

### Methods:
- `after_approval_tasks` - Returns list of tasks to complete
- `send_approval_notifications` - Sends notifications to stakeholders
- `schedule_implementation` - Schedules the approved work

### Example:
```ruby
review = ReviewCase.create!(title: "Add Dark Mode", reviewed_by: "TBD", reviewed_at: Time.current)

# Pattern 1: Use becomes! with helper method
approved = review.becomes!(ReviewCase::Approved).approve_by(reviewer: "Tech Lead")
approved.save!  # Automatically triggers post-approval actions

# Pattern 2: Use becomes! with manual attribute setting
approved = review.becomes!(ReviewCase::Approved)
approved.reviewed_by = "Tech Lead"
approved.reviewed_at = Time.current
approved.save!  # Automatically triggers post-approval actions

# Output:
# 🎉 Review case approved! Executing post-approval actions...
# 📧 Sending approval notification for: Add Dark Mode
#    ✓ Email sent to requester
#    ✓ Slack notification sent to team channel
#    ✓ Calendar invite created for kickoff meeting
# 📅 Scheduling implementation for: Add Dark Mode
#    ✓ Added to backlog
#    ✓ Assigned to development team
#    ✓ Story points estimated
```

### Tasks Performed:
- ✅ Send approval notification email to requester
- ✅ Update project management board status to 'Approved'
- ✅ Schedule implementation in next sprint
- ✅ Notify stakeholders of decision
- ✅ Archive related documents

---

## ReviewCase::Rejected - Post-Rejection Actions

After a review case is rejected, different actions are triggered:

### Methods:
- `after_rejection_tasks` - Returns list of tasks to complete
- `send_rejection_notifications` - Sends rejection notifications with feedback
- `log_rejection_metrics` - Updates analytics and metrics
- `offer_appeal_process` - Provides information about appealing the decision

### Example:
```ruby
review = ReviewCase.create!(title: "Rewrite in Rust", reviewed_by: "TBD", reviewed_at: Time.current)

# When you call reject!, the post-rejection actions are AUTOMATICALLY executed
rejected = review.reject!(reviewer: "CTO", reason: "Not aligned with tech stack")

# Output:
# ❌ Review case rejected! Executing post-rejection actions...
# 📧 Sending rejection notification for: Rewrite in Rust
#    ✓ Email sent to requester with reason: Not aligned with tech stack
#    ✓ Included appeal process documentation
# 📊 Logging rejection metrics for: Rewrite in Rust
# ⚖️ Appeal process available for: Rewrite in Rust
```

### Tasks Performed:
- ✅ Send rejection notification with detailed feedback
- ✅ Document rejection reason in knowledge base
- ✅ Offer appeal process information (30-day window)
- ✅ Schedule feedback session if requested
- ✅ Update metrics dashboard

---

## ReviewCase::Escalated - Post-Escalation Actions

After a review case is escalated, urgent actions are triggered:

### Methods:
- `after_escalation_tasks` - Returns list of urgent tasks
- `alert_management` - Sends emergency alerts to senior management
- `schedule_emergency_review` - Creates emergency meeting within 24 hours
- `halt_related_work` - Pauses all dependent tasks
- `assign_escalation_handler` - Assigns senior manager to handle the case

### Example:
```ruby
review = ReviewCase.create!(title: "Security Vulnerability", reviewed_by: "TBD", reviewed_at: Time.current)

# When you call escalate!, the post-escalation actions are AUTOMATICALLY executed
escalated = review.escalate!(reason: "Zero-day exploit discovered")

# Output:
# 🚨 Review case escalated! Executing post-escalation actions...
# 🚨 ESCALATION ALERT for: Security Vulnerability
#    ✓ Emergency notification sent to C-level
#    ✓ Management dashboard flagged
# 🔴 Scheduling emergency review for: Security Vulnerability
#    ✓ Meeting scheduled within 24 hours
# ⏸️ Halting related work for: Security Vulnerability
# 👤 Assigning escalation handler for: Security Vulnerability
```

### Tasks Performed:
- 🚨 Alert senior management immediately
- 🚨 Create emergency review meeting (within 24 hours)
- 🚨 Assign high-priority tag
- 🚨 Halt related work pending decision
- 🚨 Document escalation timeline
- 🚨 Assign escalation handler with expedited review process

---

## Comparison: STI vs Status Field

### With STI (Current Implementation):
```ruby
# Callbacks are automatically triggered when type changes
review.approve!(reviewer: "Alice")
# => Automatically calls execute_post_approval_actions
# => Which calls send_approval_notifications, schedule_implementation

# Each class has its own methods - clean separation
approved.send_approval_notifications    # Only exists on Approved
rejected.offer_appeal_process           # Only exists on Rejected
escalated.halt_related_work            # Only exists on Escalated
```

### With Status Field (Alternative):
```ruby
# Would need conditional logic and manual callback management
def approve!(reviewer:)
  self.status = 'approved'
  self.reviewed_by = reviewer
  save!

  # Manual conditional logic required
  case status
  when 'approved'
    send_approval_notifications
    schedule_implementation
  when 'rejected'
    send_rejection_notifications
    offer_appeal_process
  when 'escalated'
    alert_management
    halt_related_work
  end
end
```

## Key Benefits of STI Approach

1. **No Conditional Logic**: Each subtype has its own methods without `if/case` statements
2. **Type Safety**: Can't call `halt_related_work` on an Approved review
3. **Clear Separation**: Easy to find all Escalated-specific logic in one file
4. **Extensibility**: Adding new actions for one state doesn't affect others
5. **Maintainability**: Each subtype is self-contained and testable

## Testing

```ruby
# Test each subtype independently
describe ReviewCase::Approved do
  it "sends approval notifications" do
    approved = create(:approved_review_case)
    expect { approved.send_approval_notifications }.to output(/Email sent/).to_stdout
  end
end

describe ReviewCase::Rejected do
  it "offers appeal process" do
    rejected = create(:rejected_review_case)
    expect { rejected.offer_appeal_process }.to output(/Appeal window/).to_stdout
  end
end

describe ReviewCase::Escalated do
  it "alerts management" do
    escalated = create(:escalated_review_case)
    expect { escalated.alert_management }.to output(/ESCALATION ALERT/).to_stdout
  end
end
```

---

This demonstrates how STI allows each state to have completely different post-action workflows without cluttering the codebase with conditional logic.
