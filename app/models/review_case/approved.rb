class ReviewCase::Approved < ReviewCase
  after_save :execute_post_approval_actions, if: :saved_change_to_type?

  # Approved-specific behavior
  def can_reopen?
    true
  end

  def summary
    "#{title} was approved by #{reviewed_by} on #{reviewed_at.to_date}"
  end

  # Attribute setter method for approval
  def approve_by(reviewer:)
    self.reviewed_by = reviewer
    self.reviewed_at = Time.current
    self
  end

  # Stuff to do after approval
  def send_approval_notifications
    puts "📧 Sending approval notification for: #{title}"
  end

  def schedule_implementation
    puts "📅 Scheduling implementation for: #{title}"
  end

  private

  def execute_post_approval_actions
    puts "\n🎉 Review case approved! Executing post-approval actions...\n"
    send_approval_notifications
    schedule_implementation
  end
end
