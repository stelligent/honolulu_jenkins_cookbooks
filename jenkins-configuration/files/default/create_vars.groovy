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
import hudson.EnvVars;
import hudson.slaves.EnvironmentVariablesNodeProperty;
import hudson.slaves.EnvironmentVariablesNodeProperty.Entry;
import hudson.util.DescribableList;
import hudson.slaves.NodePropertyDescriptor;
import hudson.slaves.NodeProperty;

// takes in a list of key-value pairs, connected by equals signs and makes them Jenkins variables
// ie. groovy create_vars.groovy key1=value1 key2=value2 key3=value3

entries = new DescribableList<NodeProperty<?>,NodePropertyDescriptor>();

for (arg in args) {
 pair = arg.split('=')
 entry = new EnvironmentVariablesNodeProperty(new Entry(pair[0], pair[1]));
 entries.add(entry)
}

Hudson.instance.getGlobalNodeProperties().replaceBy(entries);

// Parse out args into variables
EnvVars entries = new EnvVars();
for (arg in args) {
    pair = arg.split('=')
    entries.put(pair[0], pair[1])
}

// Save to Jenkins
Hudson.instance.getGlobalNodeProperties()[0].getEnvVars().overrideExpandingAll(entries)