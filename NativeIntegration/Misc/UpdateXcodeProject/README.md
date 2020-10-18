# Updating Xcode project to control building of native plugins


## Description

This sample shows how to modify generated Xcode projects in order to support
various types of native plugins.

##Prerequisites

Unity: 2020

iOS: any

## How does it work



## Notes

The project contains an external Xcode project manipulation DLL among its plugins.
It's the build product of the source available
[on Unity's Bitbucket repository](https://bitbucket.org/Unity-Technologies/xcodeapi).
A preferred way to include Xcode project manipulation functionality is to copy the
C# source code files to the Assets/Editor directory in your project.
