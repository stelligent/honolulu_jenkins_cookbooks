honolulu_jenkins_cookbooks
======================
A collection of cookbooks and configuration used to set up a Jenkins server for the Honolulu application. You can point to this repo with OpsWorks if you want to create a custom Jenkins layer.

These cookbooks reference open source cookbooks that are managed using berkshelf, since it makes everything way easier. If you need to update the open source cookbooks, it's simple enough; just add the new dependency to Berksfile, and then run these commands:

```
gem install bundler
bundle install
berks install
```

OpsWorks is configured via CloudFormation to use berkshelf natively, so it is not needed nor desired to include vendor recipes specified in the Berksfile in this repo.

---

The custom cookbooks are as follows:
* apache-configuration: recipes to configure Apache proxies in front of Jenkins
* jenkins-configuration: recipes to configure Jenkins jobs, views, etc.
* rvm-config: recipes to perform post-install RVM configuration

How to use this repository
======================
This repository is designed to be used as the custom Chef cookbooks repository for a Jenkins stack built using Amazon's OpsWorks service.

We've designed the infrastructure for Honolulu Answers, as well as the Jenkins server, to be run in a VPC.

In the repository is a CloudFormation template that will handle building the appropriate VPC, IAM roles and OpsWorks stack. To run the template, you have a couple options.

Fully Automated, One Button/Command Setup
-----------------------------------------
The easier one is probably to clone this repository and run the Ruby script inside that will spin up the VPC, and then Jenkins server inside of it. To do this, [Ruby](https://www.ruby-lang.org/en/) needs to be installed on your system. You should probably install it with [RVM](http://rvm.io/) though. You'll also need the [AWS SDK for Ruby 2.0](https://github.com/aws/aws-sdk-core-ruby) which can be installed with `bundle install`.

Once both of those are installed, you can run this command to set everything up:

    ``ruby go --region aws-region-to-build-in --keyname your-ec2-keypair-name --domain yourdomain.com --email youremail@example.com``

The parameters are:

* **keyname**: the name of an EC2 keypair that exists in that region. It will be linked to the NAT and Bastion host boxes that the VPC template creates.
* **domain**: The Route 53 hosted zone that Jenkins will manipulate for its Blue/Green deployments. If you don't have a domain set up, you can leave this blank, but the Blue/Green jobs will fail if you try to run them.
* **region**: The AWS region you want to run everything in. Defaults to US-West-2, Oregon.
* **email**: The email address of the admin who will receive build and pipeline acceptance emails.
* **--no-opsworks**: Creates the environment without the use of OpsWorks. **This is a WIP, currently not recommended**

###Current Known Issues###
* **--no-opsworks**: The build currently fails. The stack completes, but chef doesnt set up Jenkins properly.
* **create-new-jenkins**: The create-new-jenkins job within Jenkins fails to properly spin up a new working Jenkins instance. (OpsWorks failure.log: HTTP Request Returned 404 Not Found: Object not found: /reports/nodes/jenkins1.localdomain/runs)

Manual Template Option
----------------------
Your other option is to run the template manually yourself. You will need the [AWS CLI tool installed and configured](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html). Then, just pull down the repo and run these commands:

    aws cloudformation create-stack --stack-name "Honolulu" --template-body "`cat honolulu.template`" --region your-region --parameters ParameterKey=KeyName,ParameterValue=your-ec2-keypair -capabilities="CAPABILITY_IAM" --parameters ParameterKey=domain,ParameterValue="yourdomain.com"   ParameterKey=adminEmailAddress,ParameterValue="you@example.com"

The parameters for those templates are as follows:

* **region**: The AWS region you want to run everything in.
* **keyname**: the name of an EC2 keypair that exists in that region. It will be linked to the NAT and Bastion host boxes that the VPC template creates.
* **domain**: The Route 53 hosted zone that Jenkins will manipulate for its Blue/Green deployments. If you don't have a domain set up, you can pass in a dummy one (example.com will work), but the Blue/Green jobs will fail if you try to run them.

The Jenkins template also supports two other optional parameters: _repository_ and _branch_. If you'd like to specify a github repository other than the Honolulu Answers app, you can pass in a parameter. The URL must be a github repository, and it must be a public repo. You can also specify a branch if you need one.

    --parameters ParameterKey=repository,ParameterValue=https://github.com/yourgithubrepo.git
    --parameters ParameterKey=branch,ParameterValue=your_branch_name
    
**Note**: When your Jenkins server comes up, it will have security turned on. The username / password will be admin / admin, though you'll likely want to change that.

* Log in to Jenkins as admin
* Click the "People" link on the right
* Click the "admin" link
* Click "configure"
* Punch in your new password in the password fields and click save.

Updating Jenkins Configuration
==============================
If you've made changes to the Jenkins server configuration, it will not be persisted if the server goes down. If you'd like to commit that configuration to a source control repo, fork this repo and look in the jenkins-configuration cookbook. In there you will find various ERB template files, each full of XML. These are the raw Jenkins configuration files. You can find this XML by configuring the jobs on the Jenkins server, and then changing the URL. The Jenkins job configure URL will end in /jobname/configure; if you go to /jobname/config.xml you'll see the pure XML. 

The templates don't do much templating (only the source control repo URL) so you can just copy the XML and paste it into the template file.

**experimental**: There's a script in the cdri repo which will look at an existing Jenkins server and extract the jobs. To try it, check out the cdri repo and run these commands (assuming you have the cdri and jenkins_chef_cookbooks repos checked out side by side):

    ruby bin/export_jenkins_jobs.rb --server http://jenkinsserver/ --repo https://github.com/stelligent/honolulu_answers.git
    cp -R /tmp/jenkins-jobs/*.xml.erb ../jenkins_chef_cookbooks/jenkins-configuration/templates/default/
    cd ../jenkins_chef_cookbooks
    git status
    
If you like what you see, you can commit the changes.

**Note**: The groovy scripts that inject the job configuration will crash and burn if there is any whitespace at the beginning of the file. Make sure that there isn't any whitespace at the beginning of the the XML configuration file. 

Pushing Jenkins changes to production
=====================================
Most of the job knowledge is stored in scripts that are stored in the application repository, but if you create or delete jobs, or make configuration changes to the jobs (...which really shouldn't be necessary!) you may need to push a new Jenkins out to the world.

You have two options: you can manually run the CloudFormation script as detailed above, or there are two Jenkins jobs you can run to update the Jenkins server.

The two jobs in question are:

* **create-new-jenkins**: this job will kick off the create-new-jenkins.sh, which should contain a script that runs the cloudformation script. You can probably just steal [the one we wrote for over here.](https://github.com/stelligent/honolulu_answers/blob/master/pipeline/create-new-jenkins.sh)
* **become-production-jenkins**: this job will call the script to change the Route 53 entry for your pipeline resource record. Changing Route 53 entries is a huge pain, so maybe you would like to steal [the ruby script we wrote exactly for that purpose](https://github.com/stelligent/honolulu_answers/blob/master/pipeline/bin/route53switch.rb)?

Then, when you need a new Jenkins, just run the create-new-jenkins job. Once it completes, go into the OpsWorks console to find your new stack, open it up, and then run the become-production-jenkins job on that server and it'll become the new production instance.

Questions?
==========
If you have any issues, feel free to open an issue or make a pull request. Alternatively, you can reach out on twitter: @jonathansywulak

:books: 

## LICENSE

Copyright (c) 2014 Stelligent Systems LLC

MIT LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
