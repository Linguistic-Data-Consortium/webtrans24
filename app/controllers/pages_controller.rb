class PagesController < ApplicationController

  def home
    if signed_in?
      redirect_to user_path(@current_user)
    else
      if Server.count == 0
        Server.create(name: '')
        helpers.annotations_setup([])
      end
      @server = Server.new
      @failed = true # prevents repeated checking of the db in views
      @title = "Home"
      @user = User.new
    end
  end

  def versions
    @git = `git log | head -3`.chomp.split("\n")
    @tag = `git describe`
    @gems = `cat Gemfile.lock`
  end

  def echo
    respond_to do |format|
      format.json do
        render json: { time: Time.now.to_s, version: 2 }
      end
      format.html do
        render plain: Time.now.to_s
      end
    end
  end

  def sqlite2postgres
    dba = Sequel.connect database: File.absolute_path("db/development.sqlite3"), adapter: 'sqlite'
    dbb = Sequel.connect ActiveRecord::Base.connection_config
    tables = dba.fetch("SELECT name FROM sqlite_master WHERE type='table';").to_a.map do |row|
      name = row[:name]
      name unless name.in? %w[ sqlite_sequence schema_migrations ar_internal_metadata ]
    end.compact
    tables.delete 'games'
    tables.unshift 'games'
    tables.map do |x|
      dba.fetch("select * from #{x} order by id").to_a.map do |y|
        y.delete :id
        y.delete :meta if x.in? %[ kits task_users ]
        y.delete :game_variant_id if x == 'kits'
        y.delete :data_set_id if x == 'tasks'
        y.delete :type if x == 'workflows'
        dbb[x.to_sym].insert y
      end
    end
    NodeValue.where(id:0).first_or_create
  end

end
