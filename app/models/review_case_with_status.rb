# This model demonstrates the status-based approach (what we're comparing against STI)
# Notice how all logic is consolidated in one class with conditional branches
class ReviewCaseWithStatus < ApplicationRecord
  self.table_name = 'review_cases_with_status'

  # Using Rails enum for status management with string values
  enum :status, { pending: 'pending', approved: 'approved', rejected: 'rejected', escalated: 'escalated' }, default: :pending

  validates :title, presence: true

  # Status-specific validations require conditionals
  validates :reviewed_by, presence: true, if: -> { approved? || rejected? }
  validates :reviewed_at, presence: true, if: -> { approved? || rejected? }
  validates :rejection_reason, presence: true, if: :rejected?
  validates :escalation_reason, presence: true, if: :escalated?

  # Callback to handle post-transition actions
  # Notice: This is ONE callback with conditionals for ALL states
  after_save :execute_post_transition_actions, if: :saved_change_to_status?

  # State transition methods
  # Note: We define our own because enum-generated bang methods don't accept params
  def approve!(reviewer:)
    self.status = :approved
    self.reviewed_by = reviewer
    self.reviewed_at = Time.current
    save!
  end

  def reject!(reviewer:, reason:)
    self.status = :rejected
    self.reviewed_by = reviewer
    self.reviewed_at = Time.current
    self.rejection_reason = reason
    save!
  end

  def escalate!(reason:)
    self.status = :escalated
    self.escalation_reason = reason
    save!
  end

  # Status-specific behavior requires conditionals
  def can_reopen?
    approved?
  end

  def can_appeal?
    rejected?
  end

  def requires_manager_review?
    escalated?
  end

  def priority
    escalated? ? 'high' : 'normal'
  end

  def summary
    case status
    when 'approved'
      "#{title} was approved by #{reviewed_by} on #{reviewed_at.to_date}"
    when 'rejected'
      "#{title} was rejected by #{reviewed_by}: #{rejection_reason}"
    when 'escalated'
      "#{title} has been escalated: #{escalation_reason}"
    else
      "#{title} is pending review"
    end
  end

  # Post-approval actions (same as STI::Approved but in one class)
  def send_approval_notifications
    puts "📧 Sending approval notification for: #{title}"
  end

  def schedule_implementation
    puts "📅 Scheduling implementation for: #{title}"
  end

  # Post-rejection actions (same as STI::Rejected but in one class)
  def send_rejection_notifications
    puts "📧 Sending rejection notification for: #{title}"
  end

  def log_rejection_metrics
    puts "📊 Logging rejection metrics for: #{title}"
  end

  def offer_appeal_process
    puts "⚖️ Appeal process available for: #{title}"
  end

  # Post-escalation actions (same as STI::Escalated but in one class)
  def alert_management
    puts "🚨 ESCALATION ALERT for: #{title}"
  end

  def schedule_emergency_review
    puts "🔴 Scheduling emergency review for: #{title}"
  end

  def halt_related_work
    puts "⏸️ Halting related work for: #{title}"
  end

  def assign_escalation_handler
    puts "👤 Assigning escalation handler for: #{title}"
  end

  private

  # ONE callback method with conditional logic for ALL states
  # Compare this to STI where each subtype has its own callback
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
end
