class CreateCachedPages < ActiveRecord::Migration
  def change
    create_table :cached_pages do |t|
      t.string :key
      t.text :value

      t.timestamps
    end
    add_index :cached_pages, :key
  end
end
