class AddBackupCodesDigestToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :backup_codes_digest, :text, array: true
  end
end
