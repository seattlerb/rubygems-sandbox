# -*- coding: utf-8 -*-
require 'rubygems/command'
require 'rubygems/dependency_installer'
require 'rubygems/commands/update_command' # for the hack below

##
# Gem command to "sandbox" command-line tools into their own private
# gem repos but with a globally command-line wrapper.

class Gem::DependencyInstaller
  attr_accessor :bin_dir
end

class Gem::Commands::UpdateCommand < Gem::Command # HACK
  attr_accessor :updated
end

class Gem::Commands::SandboxCommand < Gem::Command
  VERSION = "1.2.0"

  def initialize
    defaults = Gem::DependencyInstaller::DEFAULT_OPTIONS.merge(
      :generate_rdoc     => false,
      :generate_ri       => false,
      :document          => [],
      :format_executable => false,
      :version           => Gem::Requirement.default
    )

    super("sandbox", "Privately install a command-line tool", defaults)

    @scripts = []
  end


  def arguments # :nodoc:
    ['SUBCOMMAND    one of: list, install, help, etc... see help for full list',
     'GEMNAME       name of a gem to sandbox'].join "\n"
  end

  def usage # :nodoc:
    "#{program_name} SUBCOMMAND GEMNAME(S)"
  end

  def description
    <<-EOF

`gem sandbox` helps you manage your command-line tools and their
dependencies. Sandboxed gems are installed in their own private
repositories with their dependencies. This means that you don't have
to have a rats nest of gems in your global repository in order to run
popular command-tools like rdoc, flog, flay, rcov, etc.

`gem sandbox` has the following sub-commands:

  * list                               - list current sandboxes
  * install   gem_name ...             - install 1 or more gems
  * outdated  gem_name ...             - check 1 or more gems for outdated deps
  * plugin    gem_name plugin_name ... - install a gem and plugins for it
  * uninstall gem_name ...             - uninstall 1 or more gems
  * cleanup   gem_name ...             - remove older gem deps
  * update    gem_name ...             - update 1 or more gems
  * help                               - show this output

Once you install `gem sandbox` will output something like:

    Copy the following scripts to any directory in your path to use them:

    cp /Users/USER/.gem/sandboxes/TOOL/bin/TOOL _in_your_$PATH_

Copy the scripts to a directory in your path (eg ~/bin or /usr/bin)
and you're good to go.
    EOF
  end

  def execute
    cmd = options[:args].shift

    case cmd
    when "list" then
      list
    when "install" then
      install
    when "outdated" then
      outdated
    when "update" then
      update
    when "clean", "cleanup" then
      clean
    when "plugin" then
      plugin
    when "uninstall" then
      uninstall
    when "help", "usage" then
      show_help
      abort
    else
      alert_error "Unknown sandbox subcommand: #{cmd}"
      show_help
      abort
    end
  end

  def sandboxes
    if File.directory? sandbox_home then
      Dir.chdir sandbox_home do
        Dir["*"]
      end
    end
  end

  def list
    boxes = self.sandboxes
    if boxes then
      say boxes.join "\n"
    else
      say "No sandboxes installed."
    end
  end

  def install
    get_all_gem_names.each do |gem_name|
      install_gem gem_name
    end

    list_scripts
  end

  def uninstall
    get_all_gem_names.each do |gem_name|
      uninstall_gem gem_name
    end

    say ""
    say "You will need to manually clean up any script wrappers you copied."
  end

  def outdated
    get_all_gem_names.each do |gem_name|
      dir = sandbox_dir(gem_name)

      # Forces reset of known installed gems so subsequent repeats work
      Gem.use_paths dir, dir
      Gem.refresh

      Gem::Specification.outdated.sort.each do |name|
        local      = Gem::Specification.find_all_by_name(name).max
        dep        = Gem::Dependency.new local.name, ">= #{local.version}"
        remotes, _ = Gem::SpecFetcher.fetcher.spec_for_dependency dep

        next if remotes.empty?

        remote = remotes.last.first
        say "#{local.name} (#{local.version} < #{remote.version})"
      end
    end
  end

  def update
    require 'rubygems/commands/update_command'

    get_all_gem_names.each do |gem_name|
      dir = sandbox_dir gem_name

      # Forces reset of known installed gems so subsequent repeats work
      Gem.use_paths dir, dir
      Gem.refresh

      updater = Gem::Commands::UpdateCommand.new
      updater.updated = [] # HACK: this is stupid
      updater.installer =
        Gem::DependencyInstaller.new(options.merge(:install_dir => dir))

      Gem::Specification.outdated.sort.each do |name|
        updater.update_gem name
      end
    end
  end

  def clean
    require 'rubygems/uninstaller'

    options[:args] = sandboxes if options[:args].empty?

    get_all_gem_names.each do |gem_name|
      dir = sandbox_dir gem_name

      # Forces reset of known installed gems so subsequent repeats work
      Gem.use_paths dir, dir # FUCK ME this is the worst code ever
      Gem.refresh

      primary_gems = {}

      Gem::Specification.each do |spec|
        if primary_gems[spec.name].nil? or
            primary_gems[spec.name].version < spec.version then
          primary_gems[spec.name] = spec
        end
      end

      gems_to_cleanup = Gem::Specification.to_a

      gems_to_cleanup = gems_to_cleanup.select { |spec|
        primary_gems[spec.name].version != spec.version
      }

      deplist = Gem::DependencyList.new
      gems_to_cleanup.uniq.each do |spec| deplist.add spec end

      deps = deplist.strongly_connected_components.flatten.reverse

      deps.each do |spec|
        options[:args] = [spec.name]

        uninstall_options = {
          :executables => false,
          :version => "= #{spec.version}",
        }

        uninstaller = Gem::Uninstaller.new spec.name, uninstall_options

        begin
          uninstaller.uninstall
        rescue Gem::DependencyRemovalException, Gem::InstallError,
          Gem::GemNotInHomeException, Gem::FilePermissionError => e
          say "Unable to uninstall #{spec.full_name}:"
          say "\t#{e.class}: #{e.message}"
        end
      end
    end
  end

  def plugin
    gem_name, *plugins = options[:args]
    dir                = sandbox_dir gem_name

    install_gem gem_name, dir

    plugins.each do |plugin_name|
      inst = Gem::DependencyInstaller.new options.merge(:install_dir => dir)
      inst.install plugin_name, options[:version]
    end

    list_scripts
  end

  def list_scripts
    say ""
    say "Copy the following scripts to any directory in your path to use them:"
    say ""
    say "cp #{@scripts.join ' '} _in_your_$PATH_"
  end

  def sandbox_home
    File.join Gem.user_home, '.gem', "sandboxes"
  end

  def sandbox_dir gem_name
    File.join sandbox_home, gem_name
  end

  def install_gem gem_name, dir = sandbox_dir(gem_name)
    # Forces reset of known installed gems so subsequent repeats work
    Gem.use_paths nil, nil

    inst = Gem::DependencyInstaller.new options.merge(:install_dir => dir)
    inst.install gem_name, options[:version]

    spec = inst.installed_gems.find { |s| s.name == gem_name }
    rewrite_executables dir, spec

    say "Successfully installed #{gem_name}"
  end

  def uninstall_gem gem_name, dir = sandbox_dir(gem_name)
    # Forces reset of known installed gems so subsequent repeats work
    Gem.use_paths nil, nil

    require "fileutils"

    FileUtils.rm_rf dir, :verbose => true
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

      @scripts << path
    end
  end
end
