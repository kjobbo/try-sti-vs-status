class ReviewCase < ApplicationRecord
  validates :title, presence: true
  validates :reviewed_by, presence: true 
  validates :reviewed_at, presence: true

  # Set default type for base class instances
  after_initialize :set_default_type, if: :new_record?

  def set_default_type
    self.type ||= 'ReviewCase'
  end

  # Type helper methods
  def approved?
    is_a?(ReviewCase::Approved)
  end

  def rejected?
    is_a?(ReviewCase::Rejected)
  end

  def escalated?
    is_a?(ReviewCase::Escalated)
  end

  # Query helpers
  def status
    type.demodulize.downcase
  end
end
