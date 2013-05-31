/*
 * Jakefile
 * LPKit
 *
 * Created by Ludwig Pettersson on November 9, 2009.
 * Updated by Udo Schneider on May 31, 2013
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

//===========================================================
//  DO NOT REMOVE
//===========================================================

var SYS = require("system"),
    ENV = SYS.env,
    FILE = require("file"),
    OS = require("os");


//===========================================================
//  USER CONFIGURABLE VARIABLES
//===========================================================

/*
    The directory in which the project will be built. By default
    it is built in $CAPP_BUILD if that is defined, otherwise
    in a "Build" directory within the project directory.
*/
var buildDir = ENV["BUILD_PATH"] || ENV["CAPP_BUILD"] || "Build";

/*
    The list of directories containing Objective-J source
    that should be compiled by jake. The main framework
    directory is always checked for Objective-J source,
    you only need to edit this if you have source in
    subdirectories. Do NOT include a leading ortrailing slash
    in the directory name.

    Example:

    var sourceDirs = [
            "Core",
            "Modules",
            "Modules/Foo",
            "Modules/Bar"
        ];
*/
var sourceDirs = [
    ];


 //===========================================================
 //  AUTOMATICALLY GENERATED
 //
 //  Do not edit! (unless you know what you are doing)
 //===========================================================

var stream = require("narwhal/term").stream,
    JAKE = require("jake"),
    task = JAKE.task,
    CLEAN = require("jake/clean").CLEAN,
    CLOBBER = require("jake/clean").CLOBBER,
    FileList = JAKE.FileList,
    filedir = JAKE.filedir,
    framework = require("cappuccino/jake").framework,
    browserEnvironment = require("objective-j/jake/environment").Browser,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    productName = "LPKit",
    buildPath = FILE.canonical(FILE.join(buildDir, productName + ".build")),
    packageFrameworksPath = FILE.join(SYS.prefix, "packages", "cappuccino", "Frameworks"),
    debugPackagePath = FILE.join(packageFrameworksPath, "Debug", productName);
    releasePackagePath = FILE.join(packageFrameworksPath, productName);

var frameworkTask = framework (productName, function(frameworkTask)
{
    frameworkTask.setBuildIntermediatesPath(FILE.join(buildPath, configuration));
    frameworkTask.setBuildPath(FILE.join(buildDir, configuration));

    frameworkTask.setProductName(productName);
    frameworkTask.setIdentifier("com.luddep.LPKit");
    frameworkTask.setVersion("0.1");
    frameworkTask.setAuthor("Ludwig Pettersson");
    frameworkTask.setEmail("luddep@gmail.com");
    frameworkTask.setSummary("A collection of re-usable views, controls & utilities for Cappuccino.");

    var includes = sourceDirs.map(function(dir) { return dir + "/*.j"; }),
        fileList = new FileList();

    includes.unshift("*.j");
    fileList.include(includes);
    frameworkTask.setSources(fileList);
    frameworkTask.setResources(new FileList("Resources/**/*"));
    frameworkTask.setFlattensSources(true);
    frameworkTask.setInfoPlistPath("Info.plist");
    frameworkTask.setLicense(BundleTask.License.LGPL_v2_1);
    //frameworkTask.setEnvironments([browserEnvironment]);

    if (configuration === "Debug")
        frameworkTask.setCompilerFlags("-DDEBUG -g");
    else
        frameworkTask.setCompilerFlags("-O");
});

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("default", ["release"]);

var frameworkCJS = FILE.join(buildDir, configuration, "CommonJS", "cappuccino", "Frameworks", productName);

filedir (frameworkCJS, [productName], function()
{
    if (FILE.exists(frameworkCJS))
        FILE.rmtree(frameworkCJS);

    FILE.copyTree(frameworkTask.buildProductPath(), frameworkCJS);
});

task ("build", [productName, frameworkCJS]);

task ("all", ["debug", "release"]);

task ("install", ["debug", "release"], function()
{
    install("copy");
});

task ("install-symlinks", ["debug", "release"], function()
{
    install("symlink");
});

task ("help", function()
{
    var app = JAKE.application().name();

    colorPrint("--------------------------------------------------------------------------", "bold+green");
    colorPrint("LPKit - Framework", "bold+green");
    colorPrint("--------------------------------------------------------------------------", "bold+green");

    describeTask(app, "debug", "Builds a debug version at " + FILE.join(buildDir, "Debug", productName));
    describeTask(app, "release", "Builds a release version at " + FILE.join(buildDir, "Release", productName));
    describeTask(app, "all", "Builds a debug and release version");
    describeTask(app, "install", "Builds a debug and release version, then installs in " + packageFrameworksPath);
    describeTask(app, "install-symlinks", "Builds a debug and release version, then symlinks the built versions into " + packageFrameworksPath);
    describeTask(app, "clean", "Removes the intermediate build files");
    describeTask(app, "clobber", "Removes the intermediate build files and the installed frameworks");

    colorPrint("--------------------------------------------------------------------------", "bold+green");
});

CLEAN.include(buildPath);
CLOBBER.include(FILE.join(buildDir, "Debug", productName))
       .include(FILE.join(buildDir, "Release", productName))
       .include(debugPackagePath)
       .include(releasePackagePath);

var install = function(action)
{
    var packageFrameworksPath = FILE.join(SYS.prefix, "packages", "cappuccino", "Frameworks");

    ["Release", "Debug"].forEach(function(aConfig)
    {
        colorPrint((action === "symlink" ? "Symlinking " : "Copying ") + aConfig + "...", "cyan");

        if (aConfig === "Debug")
            packageFrameworksPath = FILE.join(packageFrameworksPath, aConfig);

        if (!FILE.isDirectory(packageFrameworksPath))
            sudo(["mkdir", "-p", packageFrameworksPath]);

        var buildPath = FILE.absolute(FILE.join(buildDir, aConfig, productName)),
            targetPath = FILE.join(packageFrameworksPath, productName);

        if (action === "symlink")
            directoryOp(["ln", "-sf", buildPath, targetPath]);
        else
            directoryOp(["cp", "-rf", buildPath, targetPath]);
    });
};

var directoryOp = function(cmd)
{
    var targetPath = cmd[cmd.length - 1];

    if (FILE.isDirectory(targetPath))
        sudo(["rm", "-rf", targetPath]);

    sudo(cmd);
};

var sudo = function(cmd)
{
    if (OS.system(cmd))
        OS.system(["sudo"].concat(cmd));
};

var describeTask = function(application, task, description)
{
    colorPrint("\n" + application + " " + task, "violet");
    description.split("\n").forEach(function(line)
    {
        stream.print("   " + line);
    });
};

var colorPrint = function(message, color)
{
    var matches = color.match(/(bold(?: |\+))?(.+)/);

    if (!matches)
        return;

    message = "\0" + matches[2] + "(" + message + "\0)";

    if (matches[1])
        message = "\0bold(" + message + "\0)";

    stream.print(message);
};
