#-------------------------------------------------------------------------------
# Copyright 2018 Cognizant Technology Solutions
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy
# of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#-------------------------------------------------------------------------------

request = require('request')
restart = require('./restart.js')
setwrkflow = require('./setwrkflow.js')

module.exports = (robot) ->
	getworkflow = new RegExp('@'+process.env.HUBOT_NAME+' getWorkflowFile (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match getworkflow
		(msg) ->
			botname = msg.match[1]
			options = {
				url: process.env.ONBOTS_URL+"/getworkflowjson/workflow.json/"+botname,
				method: "GET"
			}
			request.get options, (error, response, body) ->
				if body.indexOf("Error from server")==-1
					msg.send "Here is the workflow.json content your bot is having:\n``` json\n"+body+"```"
				else
					msg.send "``` json\n"+body+"```"
	)
	setworkflow = new RegExp('@'+process.env.HUBOT_NAME+' setWorkflowFile (.*) (.*)')
	robot.listen(
		(message) ->
			return unless message.text
			message.text.match setworkflow
		(msg) ->
			botname = msg.match[1]
			fileid = msg.match[2]
			msg.send "Your file will be copied and bot will be restarted soon. Please wait.."
			setwrkflow.setworkflow botname, fileid, (err, response, body) ->
				if response=='copied'
					restart.restartbot botname, (error, body) ->
						if error==null
							msg.send body+" "+botname+" successfully"
						else
							msg.send error
				
	)
