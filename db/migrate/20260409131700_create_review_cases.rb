class CreateReviewCases < ActiveRecord::Migration[8.1]
  def change
    create_table :review_cases do |t|
      t.string :type, null: false
      t.string :title, null: false
      t.text :description
      t.string :reviewed_by
      t.datetime :reviewed_at
      t.text :rejection_reason
      t.text :escalation_reason

      t.timestamps
    end

    add_index :review_cases, :type
  end
end
