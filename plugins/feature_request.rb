#todo style app that keeps track of features we wish to implement for steggybot

require 'cinch'
require 'yaml'

class FeatureRequest
	include Cinch::Plugin

	match /add task (.+)/i, method: :add
	match /list tasks/i, method: :list

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
	    store_tasks.close
	
	    m.reply "#{m.user.nick}: Request received and rendered ##{new_task}"
	end

	def list(m)
		tasks = get_tasks || []
		if tasks == []
			m.reply "No one has requested a feature yet."
		else
			m.reply "#{m.user.nick}: Listing requested features & their statuses"
			tasks.each do |task|
				m.reply "#{task["task"]}"
				#m.reply "task: #{task["task"]}, progress: #{task["progress"]}, claim: #{task["claim"]}"
			end


		end
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