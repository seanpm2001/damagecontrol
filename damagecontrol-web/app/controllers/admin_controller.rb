#require 'rscm'
#require 'rscm/tracker'

class AdminController < ApplicationController

  def new_project
    redirect_to(:controller => "project", :action => "view")
  end

end
