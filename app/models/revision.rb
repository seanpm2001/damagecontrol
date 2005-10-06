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
  # If zip is true, also creates a zip file
  def sync_working_copy(zipper=DamageControl::Zipper.new)
    logger.info "Syncing working copy for #{project.name} with revision #{identifier} ..." if logger
    project.scm.checkout(identifier) if project.scm
    logger.info "Done Syncing working copy for #{project.name} with revision #{identifier}" if logger

    # Now update the project settings if this revision has a damagecontrol.yml file
    update_project_settings
    
    # Make a zip of the working copy so it can be downloaded by a distributed builder.
    zip(zipper)
  end

  # Creates a new (pending) build for this revision
  # Returns the created Build object.
  def request_build(reason, triggering_build=nil)
    builds.create(:reason => reason, :triggering_build => triggering_build)
  end
  
  # Environment variables to set when building this revision.
  def build_environment
    {
      "DAMAGECONTROL_BUILD_LABEL" => identifier.to_s,
      "PKG_BUILD" => identifier.to_s,
      "DAMAGECONTROL_CHANGED_FILES" => revision_files.collect{|f| f.path}.join(',')
    }
  end
  
private

  def update_project_settings
    damagecontrol_yml = revision_files.detect do |file| 
      file.path == "damagecontrol.yml"
    end

    if(damagecontrol_yml)
      damagecontrol_yml_file = File.join(project.scm.checkout_dir, "damagecontrol.yml")
      if(File.exist?(damagecontrol_yml_file))
        logger.info "Importing project settings from #{damagecontrol_yml_file}" if logger
        project.populate_from_hash(YAML.load_file(damagecontrol_yml_file))
        project.save
      else
        logger.info "Where is #{damagecontrol_yml_file} ??? Should be here by now" if logger
      end
    end
  end
  
  # Zips up the working copy and adds an XML file with metadata that can be read
  # by XStream (http://xstream.codehaus.org/). This will be read by build slaves
  # that are Java webstart (http://java.sun.com/products/javawebstart/) apps that 
  # can be downloaded from the DC server (not yet written).
  def zip(zipper)
    return unless project.scm && project.scm.checkout_dir 
    zipdir = project.scm.checkout_dir
    zipfile_name = project.zip_dir + "/#{identifier}.zip"
    
    # TODO use this when we have implemented 'array' editing in the web interface
    # excludes = project.generated_files

    excludes = []
    zipper.zip(zipdir, zipfile_name, excludes) do |zipfile|
      zipfile.file.open("damagecontrol_build_info.yml", "w") do |f| 
        f.puts("<build_info>")
        f.puts("  <revision>#{identifier}</revision>")
        f.puts("  <build_command>#{project.build_command}</build_command>")
        f.puts("  <env-vars>")
        f.puts("    <map>")

        build_environment.each do |k, v|
        f.puts("      <entry>")
        f.puts("        <string>#{k}</string>")
        f.puts("        <string>#{v}</string>")
        f.puts("      </entry>")
        end

        f.puts("    </map>")
        f.puts("  </env-vars>")
        f.puts("</build_info>")
      end
    end    
  end
  
end

# Adaptation to make it possible to create an AR Revision
# from an RSCM one
class RSCM::Revision
  attr_accessor :project_id
  
  def stringify_keys!
  end
  
  def reject
    {
      "project_id" => project_id,
      "identifier" => identifier,
      "developer" => developer,
      "message" => message,
      "timepoint" => time
    }
  end
end