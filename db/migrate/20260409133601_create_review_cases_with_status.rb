class CreateReviewCasesWithStatus < ActiveRecord::Migration[8.1]
  def change
    create_table :review_cases_with_status do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: 'pending'
      t.string :reviewed_by
      t.datetime :reviewed_at
      t.text :rejection_reason
      t.text :escalation_reason

      t.timestamps
    end

    add_index :review_cases_with_status, :status
  end
end
