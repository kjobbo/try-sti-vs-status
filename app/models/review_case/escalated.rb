class ReviewCase::Escalated < ReviewCase
  validates :escalation_reason, presence: true

  after_save :execute_post_escalation_actions, if: :saved_change_to_type?

  # Escalated-specific behavior
  def requires_manager_review?
    true
  end

  def priority
    "high"
  end

  def summary
    "#{title} has been escalated: #{escalation_reason}"
  end

  # Attribute setter method for escalation
  def escalate_for(reason:)
    self.escalation_reason = reason
    self
  end

  # Stuff to do after escalation
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

  def execute_post_escalation_actions
    puts "\n🚨 Review case escalated! Executing post-escalation actions...\n"
    alert_management
    schedule_emergency_review
    halt_related_work
    assign_escalation_handler
  end
end
