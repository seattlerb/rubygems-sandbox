# -*- coding: utf-8 -*-
require 'rubygems/command'
require 'rubygems/dependency_installer'
# require 'rubygems/version_option'
# require 'rubygems/text'
# require 'rubygems/installer'
# require 'rubygems/local_remote_options'

##
# Gem command to "sandbox" command-line tools into their own private
# gem repos but with a globally command-line wrapper.

class Gem::DependencyInstaller
  attr_accessor :bin_dir
end

class Gem::Commands::SandboxCommand < Gem::Command
  VERSION = '1.0.0'

  def initialize
    defaults = Gem::DependencyInstaller::DEFAULT_OPTIONS.merge(
      :generate_rdoc     => false,
      :generate_ri       => false,
      :format_executable => false,
      :version           => Gem::Requirement.default
    )

    # FIX: improve desc
    super("sandbox", "Sandbox a gem's command-line tools", defaults)
  end

  # TODO: gem sandbox omnifocus --plugins omnifocus-redmine omnifocus-github
  # TODO: or should we autosupport pkg-plugin naming convention?

  def execute
    # TODO Shouldn't be Gem.user_home. We want to install global wrapper
    # TODO: need to write to /usr/bin/XXX so we need sudo support.
    get_all_gem_names.each do |gem_name|
      # Forces reset of known installed gems so subsequent repeats work
      Gem.use_paths nil, nil

      dir = File.join Gem.user_home, '.gem', "sandboxes", gem_name
      inst = Gem::DependencyInstaller.new options.merge(:install_dir => dir)
      inst.install gem_name, options[:version]

      spec = inst.installed_gems.find { |s| s.name == gem_name }
      rewrite_executables dir, spec

      inst.installed_gems.each do |spec|
        say "Successfully installed #{spec.full_name}"
      end
    end
  end

  def rewrite_executables dir, spec
    spec.executables.each do |filename|
      path = File.join dir, "bin", filename
      env  = "ENV['GEM_HOME'] = ENV['GEM_PATH'] = #{dir.inspect}"

      script = File.read path
      script.sub!(/require 'rubygems'/, "#{env}\n\\&")

      File.open path, "w" do |f|
        f.write script
      end

      # TODO: copy to /usr/bin/XXX
    end
  end
end

# def arguments # :nodoc:
#   'GEMNAME       name of an installed gem to sandbox'
# end
#
# def defaults_str # :nodoc:
#   "--version='>= 0'"
# end
#
# def usage # :nodoc:
#   "#{program_name} GEMNAME [options]"
# end
#
# def description
#   "TODO"
# end
