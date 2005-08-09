require_dependency 'build'

class ProjectController < ApplicationController
  layout "application", :except => :list
  
  def index
  end

  def new
    @project = Project.new
    @project.publishers = []

    define_plugin_rows

    @submit_action = "create"
    @submit_text = "Create project"
    render :action => "settings"
  end

  def edit
    find
    
    define_plugin_rows

    @submit_action = "update"
    @submit_text = "Update project"
    render :action => "settings"
  end

  def create
    update_or_save(Project.create(@params[:project]))
  end

  def update
    update_or_save(find)
  end
  
  def show
    find
  end
  
  def list
  end
  
  def revisions_rss
    find
    render :text => @project.revisions_rss(self)
  end

  def builds_rss
    find
    render :text => @project.builds_rss(self)
  end

private

  def find
    @project = Project.find(@params[:id])
  end
  
  def update_or_save(project)
    project.scm        = deserialize_to_array(@params[:scm]).find{|scm| scm.enabled}
    project.tracker    = deserialize_to_array(@params[:tracker]).find{|tracker| tracker.enabled}
    project.scm_web    = deserialize_to_array(@params[:scm_web]).find{|scm_web| scm_web.enabled}
    project.publishers = deserialize_to_array(@params[:publisher])
    project.update_attributes(@params[:project])

    redirect_to :action => "edit", :id => project.id
  end

  def define_plugin_rows
    # Workaround for AR bug
    @project.publishers = YAML::load(@project.publishers) if @project.publishers.class == String

    @rows = [[@project], scms, publishers, trackers, scm_webs]
  end

  # Instantiates all known SCMs. The project's persisted scm
  # will also be among these, and will have the persisted attribute values.
  def scms
    RSCM::Base.classes.collect{|cls| cls.new}.collect do |scm|
      scm.class == @project.scm.class ? @project.scm : scm
    end.sort
  end

  def publishers
    DamageControl::Publisher::Base.classes.collect{|cls| cls.new}.collect do |publisher|
      already = @project.publishers.find do |p| 
        p.class.name == publisher.class.name
      end
      already ? already : publisher
    end.sort
  end

  def trackers
    DamageControl::Tracker::Base.classes.collect{|cls| cls.new}.collect do |tracker|
      tracker.class == @project.tracker.class ? @project.tracker : tracker
    end.sort
  end

  def scm_webs
    DamageControl::ScmWeb::Base.classes.collect{|cls| cls.new}.collect do |scm_web|
      scm_web.class == @project.scm_web.class ? @project.scm_web : scm_web
    end.sort
  end
end
