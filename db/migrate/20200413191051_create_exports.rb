class CreateExports < ActiveRecord::Migration[5.2]
  def change
    create_table :exports do |t|
      t.string :filename
      t.string :path

      t.timestamps
    end
  end
end
