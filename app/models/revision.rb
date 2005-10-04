class Revision < ActiveRecord::Base
  ActiveRecord::Base.default_timezone = :utc
  
  belongs_to :project
  has_many :revision_files, :dependent => true
  has_many :builds, :order => "create_time", :dependent => true
  # identifier can be String, Numeric or Time, so we YAML it to the database to preserve type info.
  # We have to fool AR to do this by wrapping it in an array - serialize doesn't work
  def identifier=(i)
    self[:identifier] = YAML::dump([i])
  end
  def identifier
     (YAML::load(self[:identifier]))[0]
  end
  
  def self.create(rscm_revision)
    revision = super(rscm_revision)

    rscm_revision.each do |rscm_file|
      revision.revision_files.create(rscm_file)
    end
    
    revision
  end

  # Syncs the working copy of the project with this revision.
  def sync_working_copy
    logger.info "Syncing working copy for #{project.name} with revision #{identifier} ..." if logger
    project.scm.checkout(identifier) if project.scm
    logger.info "Done Syncing working copy for #{project.name} with revision #{identifier}" if logger
    
    # Now update the project settings if this revision has a damagecontrol.yml file
    damagecontrol_yml = revision_files.detect {|file| file.path == "damagecontrol.yml"}
    if(damagecontrol_yml)
      damagecontrol_yml_file = File.join(project.scm.checkout_dir, "damagecontrol.yml")
      if(File.exist?(damagecontrol_yml_file))
        logger.info "Importing project settings from #{damagecontrol_yml_file}" if logger
        project.populate_from_hash(YAML.load(damagecontrol_yml_file))
        project.save
      else
        logger.info "Where is #{damagecontrol_yml_file} ??? Should be here by now" if logger
      end
    end
  end

  # Creates a new (pending) build for this revision
  # Returns the created Build object.
  def request_build(reason, triggering_build=nil)
    builds.create(:reason => reason, :triggering_build => triggering_build)
  end
  
end

# Adaptation to make it possible to create an AR Revision
# from an RSCM one
class RSCM::Revision
  attr_accessor :project_id
  
  def stringify_keys!
  end
  
  def reject
    # we could have used reflection, but this is just as easy!
    {
      "project_id" => project_id,
      "identifier" => identifier,
      "developer" => developer,
      "message" => message,
      "timepoint" => time
    }
  end
end