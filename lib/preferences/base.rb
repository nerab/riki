require 'yaml'

module Preferences
  def self.load(file_name)
    YAML::load_file(file_name)
  end

  def self.save(attribs, file_name)
    File.open(file_name, 'w') do |out|
      YAML::dump(attribs, out)
    end
  end

  module User
    FILE_NAME = 'preferences.yaml'
    
    def self.load!(namespace)
      Preferences.load(user_preferences_file(namespace))
    end

    def self.load(namespace)
      begin
        self.load!(namespace)
      rescue
        {}
      end
    end
    
    def self.save!(attribs, namespace)
      FileUtils.makedirs(user_preferences_path(namespace))
      Preferences.save(attribs, user_preferences_file(namespace))
    end
    
    def self.user_preferences_path(namespace)
      File.expand_path(File.join('~', '.config', namespace))
    end
    
    def self.user_preferences_file(namespace)
      File.join(user_preferences_path(namespace), FILE_NAME)
    end
  end
end
