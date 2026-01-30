class AddTwoFactorFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :two_factor_enabled_at, :datetime
  end
end
