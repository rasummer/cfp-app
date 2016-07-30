class CreateProgramSessions < ActiveRecord::Migration
  def change
    create_table :program_sessions do |t|
      t.references :event, index: true
      t.references :proposal, index: true
      t.text :title
      t.text :abstract
      t.references :track, index: true
      t.references :session_format, index: true
      t.text :state, default: ProgramSession::ACTIVE

      t.timestamps null: false
    end
  end
end
