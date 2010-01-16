/*
 * Jakefile
 * LPKit
 *
 * Created by Ludwig Pettersson on November 9, 2009.
 * 
 * The MIT License
 * 
 * Copyright (c) 2009 Ludwig Pettersson
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */

var ENV = require("system").env,
    FILE = require("file"),
    task = require("jake").task,
    CLEAN = require("jake/clean").CLEAN,
    FileList = require("jake").FileList,
    framework = require("cappuccino/jake").framework,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug";

framework ("LPKit", function(task)
{   
    task.setBuildIntermediatesPath(FILE.join("Build", "LPKit.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("LPKit");
    task.setIdentifier("com.luddep.LPKit");
    task.setVersion("0.1");
    task.setAuthor("Ludwig Pettersson");
    task.setEmail("luddep@gmail.com");
    task.setSummary("A collection of generic views, controls & utilities for Cappuccino.");
    task.setSources(new FileList("*.j"));
    task.setResources(new FileList("Resources/**/*"));
    task.setFlattensSources(true);
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

CLEAN.include(FILE.join("Build", "LPKit.build"));

task ("default", ["LPKit", "clean"]);
