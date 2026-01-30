class AddEmailOtpToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_code_digest, :string
    add_column :users, :otp_sent_at, :datetime
    add_column :users, :otp_attempts, :integer
  end
end
