gem 'warbler'
require 'warbler'

class Warbler::Task
  def define_appengine_consolidation_tasks
    with_namespace_and_config do |name, config|
      app_task = Rake.application.lookup("app")

      jruby_complete_jar = app_task.prerequisites.detect {|p| p =~ /jruby-complete/}
      app_task.prerequisites.delete(jruby_complete_jar)
      jruby_core_name = jruby_complete_jar.sub(/complete/, 'core')
      jruby_stdlib_name = jruby_complete_jar.sub(/complete/, 'stdlib')
      working_dir = "tmp/jar_unpack"

      task :unpack_jruby_complete_jar => jruby_complete_jar do |t|
        rm_rf working_dir
        mkdir_p "#{working_dir}/jruby_complete"
        mkdir_p "#{working_dir}/jruby_core"
        complete_jar_file = File.expand_path(t.prerequisites.first)
        Dir.chdir("#{working_dir}/jruby_complete") do
          sh "jar xf #{complete_jar_file}"
          mv FileList[*%w(builtin jruby org com jline)], "../jruby_core"
        end
        rm_f complete_jar_file
      end

      file jruby_core_name do |t|
        Rake::Task["#{name}:unpack_jruby_complete_jar"].invoke
        sh "jar cf #{t.name} -C #{working_dir}/jruby_core ."
      end

      file jruby_stdlib_name do |t|
        Rake::Task["#{name}:unpack_jruby_complete_jar"].invoke
        sh "jar cf #{t.name} -C #{working_dir}/jruby_complete ."
      end

      task :clean do
        rm_rf working_dir
      end

      task :app => [jruby_core_name, jruby_stdlib_name]

      gems_task = Rake.application.lookup("gems")
      app_task.prerequisites.delete("gems")
      gems_jar_name = File.expand_path(File.join(config.staging_dir, "WEB-INF", "lib", "gems.jar"))

      file gems_jar_name => gems_task.prerequisites do |t|
        Dir.chdir(File.join(config.staging_dir, "WEB-INF")) do
          sh "jar cf #{gems_jar_name} -C gems ."
          rm_rf "gems"
        end
      end

      task :app => gems_jar_name
    end
  end
end

warbler = Warbler::Task.new
warbler.define_appengine_consolidation_tasks

task :clean => "war:clean"

task :warble => "war"

namespace :glassfish do
  task :deploy => :warble do
    sh "asadmin deploy --name rails --contextroot rails tmp/war" do |ok, res|
      unless ok
        puts "Is the GLASSFISH/bin directory on your path?"
      end
    end
  end

  task :undeploy do
    sh "asadmin undeploy rails"
  end
end

namespace :appengine do
  
  desc 'Deploy appengine app (rake appengine:deploy EMAIL=email PASSWORD=password)'
  task :deploy => :warble do
    email = ENV['EMAIL']
    pass = ENV['PASSWORD']
    passfile = ENV['PASSWORDFILE']
    fail "Please supply your Google account email using EMAIL={email}" unless email
    fail %{Please supply your Google password using PASSWORD={pass} or PASSWORDFILE={file}.
PASSWORDFILE should only contain the password value.} unless pass || passfile
    require 'tempfile'
    tmpfile = nil
    passcmd = if pass
                tmpfile = Tempfile.new("gaepass") {|f| f << pass }
                "cat #{tmpfile.path}"
              else
                "cat #{passfile}"
              end
    sh "#{passcmd} | appcfg.sh --email=#{email} --passin --enable_jar_splitting update tmp/war" do |ok, res|
      unless ok
        puts "Is the AppEngine-SDK/bin directory on your path?"
      end
      tmpfile.unlink if tmpfile
    end
  end

  desc 'Run the dev server'
  task :server do
    sh "dev_appserver.sh --port=3000 tmp/war" do |ok, res|
      unless ok
        puts "Is the AppEngine-SDK/bin directory on your path?"
      end
    end
  end
end
