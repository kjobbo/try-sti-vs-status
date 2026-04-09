# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Creating ReviewCase examples..."
puts "Note: Watch for automatic post-transition actions!"
puts

# Clear existing data
ReviewCase.destroy_all

# Example 1: Create a base ReviewCase and approve it
puts "\n1. Creating base ReviewCase and approving it..."
puts "=" * 70
review1 = ReviewCase.create!(
  title: "New Feature Request",
  description: "User requested dark mode support",
  reviewed_by: "TBD",
  reviewed_at: Time.current
)
puts "Created: #{review1.class.name} - #{review1.title}"
puts

approved_review = review1.becomes!(ReviewCase::Approved).approve_by(reviewer: "John Doe")
approved_review.save!
puts "\nAfter becomes! and save!: #{approved_review.class.name}"
puts "Summary: #{approved_review.summary}"
puts "Can reopen? #{approved_review.can_reopen?}"

# Example 2: Create a base ReviewCase and reject it
puts "\n\n2. Creating base ReviewCase and rejecting it..."
puts "=" * 70
review2 = ReviewCase.create!(
  title: "API Change Proposal",
  description: "Proposed breaking changes to v1 API",
  reviewed_by: "TBD",
  reviewed_at: Time.current
)
puts "Created: #{review2.class.name} - #{review2.title}"
puts

rejected_review = review2.becomes!(ReviewCase::Rejected).reject_by(reviewer: "Jane Smith", reason: "Breaking changes not allowed in v1")
rejected_review.save!
puts "\nAfter becomes! and save!: #{rejected_review.class.name}"
puts "Summary: #{rejected_review.summary}"
puts "Can appeal? #{rejected_review.can_appeal?}"

# Example 3: Create a base ReviewCase and escalate it
puts "\n\n3. Creating base ReviewCase and escalating it..."
puts "=" * 70
review3 = ReviewCase.create!(
  title: "Security Vulnerability Report",
  description: "Critical security issue found in authentication",
  reviewed_by: "TBD",
  reviewed_at: Time.current
)
puts "Created: #{review3.class.name} - #{review3.title}"
puts

escalated_review = review3.becomes!(ReviewCase::Escalated).escalate_for(reason: "Requires immediate security team review")
escalated_review.save!
puts "\nAfter becomes! and save!: #{escalated_review.class.name}"
puts "Summary: #{escalated_review.summary}"
puts "Priority: #{escalated_review.priority}"
puts "Requires manager review? #{escalated_review.requires_manager_review?}"

# Example 4: Transition between states
puts "\n\n4. Demonstrating state transitions..."
puts "=" * 70
review4 = ReviewCase.create!(
  title: "Performance Optimization",
  description: "Improve query performance",
  reviewed_by: "TBD",
  reviewed_at: Time.current
)
puts "Created: #{review4.class.name}"
puts

# First escalate (triggers escalation actions)
escalated = review4.becomes!(ReviewCase::Escalated).escalate_for(reason: "Needs architecture review")
escalated.save!
puts "\nAfter becomes! and save!: #{escalated.class.name}"
puts

# Then approve after review (triggers approval actions)
approved = escalated.becomes!(ReviewCase::Approved).approve_by(reviewer: "Tech Lead")
approved.save!
puts "\nAfter becomes! and save!: #{approved.class.name}"

# Show final state
puts "\n5. Querying by STI type..."
puts "  Total ReviewCases: #{ReviewCase.count}"
puts "  Approved: #{ReviewCase::Approved.count}"
puts "  Rejected: #{ReviewCase::Rejected.count}"
puts "  Escalated: #{ReviewCase::Escalated.count}"
puts "  Base ReviewCase (not transitioned): #{ReviewCase.where(type: 'ReviewCase').count}"

puts "\n✓ Seed data created successfully!"
