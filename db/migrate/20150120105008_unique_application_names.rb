class UniqueApplicationNames < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :description, :string
    add_index :oauth_applications, :name, unique: true
  end
end
