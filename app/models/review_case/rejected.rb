class ReviewCase::Rejected < ReviewCase
  validates :rejection_reason, presence: true

  after_save :execute_post_rejection_actions, if: :saved_change_to_type?

  # Rejected-specific behavior
  def can_appeal?
    true
  end

  def summary
    "#{title} was rejected by #{reviewed_by}: #{rejection_reason}"
  end

  # Attribute setter method for rejection
  def reject_by(reviewer:, reason:)
    self.reviewed_by = reviewer
    self.reviewed_at = Time.current
    self.rejection_reason = reason
    self
  end

  # Stuff to do after rejection
  def send_rejection_notifications
    puts "📧 Sending rejection notification for: #{title}"
  end

  def log_rejection_metrics
    puts "📊 Logging rejection metrics for: #{title}"
  end

  def offer_appeal_process
    puts "⚖️ Appeal process available for: #{title}"
  end

  private

  def execute_post_rejection_actions
    puts "\n❌ Review case rejected! Executing post-rejection actions...\n"
    send_rejection_notifications
    log_rejection_metrics
    offer_appeal_process
  end
end
