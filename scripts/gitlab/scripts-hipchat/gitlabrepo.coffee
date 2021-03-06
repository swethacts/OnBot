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

###
Coffee script used for:
Creating,deleting,listing and help on a project

Set of bot commands
1. create gitlab project <projectname>
2. delete gitlab project <projectID>
3. list my projects
4. help

Env to set:
1. HUBOT_GITLAB_API
2. HUBOT_GITLAB_USER
3. HUBOT_GITLAB_TOKEN
4. HUBOT_NAME
###

request=require('request')
readjson = require ('./readjson.js')
index = require('./index')
generate_id = require('./mongoConnt')

botname = process.env.HUBOT_NAME
git_url=process.env.HUBOT_GITLAB_API
git_user=process.env.HUBOT_GITLAB_USER
git_token=process.env.HUBOT_GITLAB_TOKEN

module.exports = (robot) ->
	robot.respond /help/i, (msg) ->
		msg.send "You are having following commands\ncreate gitlab project <projectname>\nlist my projects\ncreate branch <branchname> for <projectID> from <oldbranchname>\ndelete branch <branchname> from <projectID>\nadd user <userID> to <projectID>\nremove user <userID> from <projectID>\ndelete gitlab project <projectID>\nlist members of <projectID>\nWhat do you want me to do?"
	robot.respond /list my projects/i, (msg) ->
		url=git_url+"/projects"
		options = {
		method: 'GET',
		url: url,
		headers: {'PRIVATE-TOKEN': git_token}};
		request.get options, (error, response, body) ->
			dt=""
			if(response.statusCode!=200)
				msg.send "Couldn't get project list\n"+JSON.stringify(response)
			else
				for i in [0...JSON.parse(response.body).length]
					dt+=JSON.parse(response.body)[JSON.parse(response.body).length-i-1].name+" [Project Id: "+JSON.parse(response.body)[JSON.parse(response.body).length-i-1].id+"]\n"
				msg.send dt
	
	robot.respond /create gitlab project (.*)/i, (msg) ->
		message = msg.match[0];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			newprojectname=msg.match[1]
			if stdout.gitlabcreateproject.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.gitlabcreateproject.admin,podIp:process.env.MY_POD_IP,newbranch:newbranch,projectid:projectid,oldbranch:oldbranch,msg:msg.toString(),callback_id:'gitlabcreateproject'}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command:create gitlab project '+projectid+'\n approve or reject the request'
					robot.messageRoom(stdout.gitlabcreateproject.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.gitlabcreateproject.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
					
			else
				newprojectname=msg.match[1]
				url=git_url+"/projects"
				options = {
				method: 'POST',
				url: url,
				headers: {'PRIVATE-TOKEN': git_token},
				body: {'name': newprojectname,'visibility': 'internal'},
				json: true};
				request.post options, (error, response, body) ->
					if(response.statusCode!=201)
						dt="Couldn't create project\n"+response.body.message.path
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
						dt = response.body.name+" created successfully\n"+"Id: "+response.body.id+"\nOwner: "+response.body.owner.username
						msg.send dt
						setTimeout (->index.passData dt),1000
						actionmsg = response.body.name+" created successfully\n"+"Id: "+response.body.id+"\nOwner: "+response.body.owner.username
						statusmsg = 'Success';
						index.wallData botname, message1, actionmsg, statusmsg;
	robot.router.post '/gitlabcreateproject', (req, response) ->
		userid=req.body.userid
		if(req.body.action=='Approve')
			dt=req.body.approver+" approved creation of gitlab project "+req.body.newprojectname+", requested by "+req.body.username+"\n"
			newprojectname=req.body.newprojectname
			url=git_url+"/projects"
			options = {
			method: 'POST',
			url: url,
			headers: {'PRIVATE-TOKEN': git_token},
			body: {'name': newprojectname,'visibility': 'internal'},
			json: true};
			request.post options, (error, response, body) ->
				if(response.statusCode!=201)
					dt="Couldn't create project\n"+response.body.message.path
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
				else
					dt = response.body.name+" created successfully\n"+"Id: "+response.body.id+"\nOwner: "+response.body.owner.username
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
					message = 'create gitlab project ' + newprojectname;
					actionmsg = 'Gitlab project created';
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
		else
			dt="Create Gitlab project request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom userid, dt
			setTimeout (->index.passData dt),1000
	
	robot.respond /delete gitlab project (.*)/i, (msg) ->
		message = msg.match[0];
		readjson.readworkflow_coffee (error,stdout,stderr) ->
			finaljson=stdout;
			projectid=msg.match[1]
			if stdout.gitlabdeleteproject.workflowflag
				generate_id.getNextSequence (err,id) ->
					tckid=id
					payload={botname:process.env.HUBOT_NAME,username:msg.message.user.name,userid:msg.message.user.reply_to,approver:stdout.gitlabdeleteproject.admin,podIp:process.env.MY_POD_IP,newbranch:newbranch,projectid:projectid,oldbranch:oldbranch,msg:msg.toString(),callback_id:'gitlabdeleteproject'}
					message='Ticket Id : '+tckid+'\n Raised By: '+msg.message.user.name+'\n Command:delete gitlab project '+projectid+'\n approve or reject the request'
					robot.messageRoom(stdout.gitlabdeleteproject.adminid, message);
					msg.send 'Your request is waiting for approval by '+stdout.gitlabdeleteproject.admin
					dataToInsert = {ticketid: tckid, payload: payload, "status":"","approvedby":""}
					#Insert into Mongo with Payload
					generate_id.add_in_mongo dataToInsert
			else
				projectid=msg.match[1]
				url=git_url+"/projects/"+projectid
				options = {
				method: 'DELETE',
				url: url,
				headers: {'PRIVATE-TOKEN': git_token}};
				request.delete options, (error, response, body) ->
					console.log response.statusCode
					if(response.statusCode!=202)
						dt="Couldn't delete project with the given projectID. Make sure the projectID is correct."
						msg.send dt
						setTimeout (->index.passData dt),1000
					else
                        dt="[Project Id: "+projectid+"] deleted successfully"
						msg.send dt
						setTimeout (->index.passData dt),1000
						actionmsg = "Project deleted successfully"
						statusmsg = 'Success';
						index.wallData botname, message, actionmsg, statusmsg;
	robot.router.post '/gitlabdeleteproject', (req, response) ->
		userid=req.body.userid
		if(req.body.action=='Approve')
			dt=req.body.approver+" approved deletion of gitlab project "+req.body.projectid+", requested by "+req.body.username+"\n"
			projectid=req.body.projectid
			url=git_url+"/projects/"+projectid
			options = {
			method: 'DELETE',
			url: url,
			headers: {'PRIVATE-TOKEN': git_token}};
			request.delete options, (error, response, body) ->
				console.log response.statusCode
				if(response.statusCode!=202)
					dt="Couldn't delete project with the given projectID. Make sure the projectID is correct."
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
				else
					dt="[Project Id: "+projectid+"] deleted successfully"
					robot.messageRoom userid, dt
					setTimeout (->index.passData dt),1000
					message = 'delete gitlab project ' + projectid;
					actionmsg = "Project deleted successfully"
					statusmsg = 'Success';
					index.wallData botname, message, actionmsg, statusmsg;
		else
			dt="Deletion of Gitlab project request from "+req.body.username+" was rejected by "+req.body.approver
			robot.messageRoom userid, dt
			setTimeout (->index.passData dt),1000
