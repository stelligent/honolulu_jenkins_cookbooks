//Copyright (c) 2014 Stelligent Systems LLC
//
//MIT LICENSE
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

import hudson.model.Hudson;
import hudson.model.ListView;
import hudson.model.View;
import hudson.model.Hudson;
import au.com.centrumsystems.hudson.plugin.buildpipeline.BuildPipelineView;
import au.com.centrumsystems.hudson.plugin.buildpipeline.DownstreamProjectGridBuilder;
import se.diabol.jenkins.pipeline.DeliveryPipelineView;
import se.diabol.jenkins.pipeline.DeliveryPipelineView.ComponentSpec;
import se.diabol.jenkins.pipeline.model.Component;
import se.diabol.jenkins.pipeline.model.Pipeline;
import se.diabol.jenkins.pipeline.model.Stage;
import se.diabol.jenkins.pipeline.model.Task;
import java.util.ArrayList;
import java.util.List;


def addView(title, view) {
  views = Hudson.instance.getViews();
  foundViews = views.findAll{ viewIterator ->
    viewIterator.getViewName().equals(title);
  }
  if(foundViews.size() == 0) {
    Hudson.instance.addView(view);
    println "Successfully create a view for the ${title}";
  } 
  else {
    println "The view ${title} already exists, not adding again";
  }
}
INITIAL_JOB = "trigger-stage";
pipelineViewName = "Continuous Delivery Pipeline";
pipelineView = new BuildPipelineView(pipelineViewName,
                                     pipelineViewName,
                                     new DownstreamProjectGridBuilder(INITIAL_JOB),
                                     "5",    //final String noOfDisplayedBuilds,
                                     true,   //final boolean triggerOnlyLatestJob, 
                                     null);  //final String cssUrl

addView(pipelineViewName, pipelineView);


List<DeliveryPipelineView.ComponentSpec> componentSpecs = new ArrayList<DeliveryPipelineView.ComponentSpec>();
componentSpecs.add(new DeliveryPipelineView.ComponentSpec("Delivery Pipeline", "trigger-stage"));

DeliveryPipelineView view = new DeliveryPipelineView("Delivery Pipeline View");
view.setComponentSpecs(componentSpecs);

addView("Delivery Pipeline View", view);

Hudson.instance.save();
