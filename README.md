honolulu_jenkins_cookbooks
======================

A collection of cookbooks and configuration used to set up a Jenkins server for the Honolulu application. You can point to this repo with OpsWorks if you want to create a custom Jenkins layer.

Most of these cookbooks are just copies of open source cookbooks. They were retrieved using berkshelf, since it makes everything way easier. If you need to update the open source cookbooks, it's simple enough; just add the new dependency to Berksfile, and then run these commands:

```
gem install berkshelf
berks install --path temp
cp -R temp/* .
rm -rf temp
```

(berkshelf seemed to nuke the directory that you pass in with --path, so don't just try passing in the current directory. That took me a little while to figure out...)

---

The custom cookbooks are as follows:
* jenkins-configuration: cookbooks to configure Jenkins jobs, views, etc.
* rvm: the one berkshelf pulls in is wicked old, and the override wasn't working. I just downloaded it manually.

how to use this repository
======================

This repository is design to be used as the custom Chef cookbooks repository for a Jenkins stack built using Amazon's OpsWorks service. I suppose you could use it to build a custom Jenkins server without using OpsWorks, but I haven't tried that so if you give it a shot you're on your own. :)

Included in the repository is CloudFormation template that will handle building the appropriate IAM roles and OpsWorks stack. To run it, you will need the [AWS CLI tool installed and configured](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html). Then, just pull down the repo and run this command:

    aws cloudformation create-stack --stack-name Honolulu-Jenkins --template-body "`cat jenkins.template`"  --disable-rollback  --timeout-in-minutes 60 --parameters ParameterKey=domain,ParameterValue="yourdomain.com"

The template supports three parameters: _domain_, _repository_, and _branch_. The only required one is _domain_, which is Route 53 Hosted zone you already have set up. You don't _need_ this, but without it the jobs that manipulate Route 53 entries will fail. 

If you'd like to specify a github repository other than the Honolulu Answers app, you can pass in a parameter. The URL must be a github repository, and it must be a public repo. You can also specify a branch if you need one.

    --parameters ParameterKey=repository,ParameterValue=https://github.com/yourgithubrepo.git
    --parameters ParameterKey=branch,ParameterValue=your_branch_name
    
**Note**: When your Jenkins server comes up, it will have security turned on. The username / password will be admin / admin, though you'll likely want to change that.

* Log in to Jenkins as admin
* Click the "People" link on the right
* Click the "admin" link
* Click "configure"
* Punch in your new password in the password fields and click save.

how to update jenkins configuration:
====

If you've made changes to the Jenkins server configuration, it will not be persisted if the server goes down. If you'd like to commit that configuration to a source control repo, fork this repo and look in the jenkins-configuration cookbook. In there you will find various ERB template files, each full of XML. These are the raw Jenkins configuration files. You can find this XML by configuring the jobs on the Jenkins server, and then changing the URL. The Jenkins job configure URL will end in /jobname/configure; if you go to /jobname/config.xml you'll see the pure XML. 

The templates don't do much templating (only the source control repo URL) so you can just copy the XML and paste it into the template file.

**experimental**: There's a script in the cdri repo which will look at an existing Jenkins server and extract the jobs. To try it, check out the cdri repo and run these commands (assuming you have the cdri and jenkins_chef_cookbooks repos checked out side by side):

    ruby bin/export_jenkins_jobs.rb --server http://jenkinsserver/ --repo https://github.com/stelligent/honolulu_answers.git
    cp -R /tmp/jenkins-jobs/*.xml.erb ../jenkins_chef_cookbooks/jenkins-configuration/templates/default/
    cd ../jenkins_chef_cookbooks
    git status
    
If you like what you see, you can commit the changes.

**Note**: The groovy scripts that inject the job configuration will crash and burn if there is any whitespace at the beginning of the file. Make sure that there isn't any whitespace at the beginning of the the XML configuration file. 

how to push a new version of jenkins out to the world
====

Most of the job knowledge is stored in scripts that are stored in the application repository, but if you create or delete jobs, or make configuration changes to the jobs (...which really shouldn't be necessary!) you may need to push a new Jenkins out to the world.

You have two options: you can manually run the CloudFormation script as detailed above, or there are two Jenkins jobs you can run to update the Jenkins server.

The two jobs in question are:

* **create-new-jenkins**: this job will kick off the create-new-jenkins.sh, which should contain a script that runs the cloudformation script. You can probably just steal [the one we wrote for over here.](https://github.com/stelligent/honolulu_answers/blob/master/infrastructure/create-new-jenkins.sh)
* **become-production-jenkins**: this job will call the script to change the Route 53 entry for your pipeline resource record. Changing Route 53 entries is a huge pain, so maybe you would like to steal [the ruby script we wrote exactly for that purpose](https://github.com/stelligent/honolulu_answers/blob/master/infrastructure/bin/route53switch.rb)?

Then, when you need a new Jenkins, just run the create-new-jenkins job. Once it completes, go into the OpsWorks console to find your new stack, open it up, and then run the become-production-jenkins job on that server and it'll become the new production instance.

questions?
====
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
