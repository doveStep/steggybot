#todo style app that keeps track of features we wish to implement for steggybot

require 'cinch'
require 'yaml'

class FeatureRequest
	include Cinch::Plugin

	match /add task (.+)/i, method: :add


	def initialize(*args)
		super
		@task_list = config[:task_list]
	end

	def add(m, task)
    	new_task = {"task" => task, "added_by" => m.user.nick, "created_at" => Time.now, "progress" => "not started", "claim" => "no one has claimed"}
		
		old_tasks = get_tasks || []
		combined_tasks = old_tasks << new_task

	    store_tasks = File.new(@task_list, 'w')
	    store_tasks.puts YAML.dump(combined_tasks)
	
	    m.reply "#{m.user.nick}: Request received and rendered ##{new_task}"
	end


	#--------------------------------------------------------------------------------
	# Protected
	#--------------------------------------------------------------------------------

	protected

	def get_tasks
		output = File.new(@task_list, 'r')
		tasks = YAML.load(output.read)
		output.close

		tasks
	end
end