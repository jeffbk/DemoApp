
class TidesController < ApplicationController
  def predict
    db = SQLite3::Database.new('config/harmdb')
    @rows = db.execute('select * from constituents')
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end
  end

end
