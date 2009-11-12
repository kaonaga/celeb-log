class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      t.column :login,                     :string
      t.column :email,                     :string
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
      t.column :activation_code, :string, :limit => 40
      t.column :activated_at, :datetime
      t.column :state, :string, :null => :no, :default => 'passive'
      t.column :deleted_at, :datetime
    end
    execute "insert into users (id, login, email, crypted_password, salt, created_at, updated_at, activation_code, activated_at, state) values(1, 'admin', 'admin@celeb-log.info', 'a00ffd3242389410c8feb43f2b9cdffa996a84bd', '53b9f0b18a23426b6bb5e0e707e985e937ad9fcc', '#{Time.now}', '#{Time.now}', '', '#{Time.now}', 'active')"
  end

  def self.down
    drop_table "users"
  end
end
