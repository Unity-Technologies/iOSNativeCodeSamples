using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using System.Collections;
using UnityEditor.iOS.Xcode;
using System.IO;

public class MyBuildPostprocessor {

	internal static void CopyAndReplaceDirectory(string srcPath, string dstPath)
	{
		if (Directory.Exists(dstPath))
			Directory.Delete(dstPath);
		if (File.Exists(dstPath))
			File.Delete(dstPath);

		Directory.CreateDirectory(dstPath);

		foreach (var file in Directory.GetFiles(srcPath))
			File.Copy(file, Path.Combine(dstPath, Path.GetFileName(file)));

		foreach (var dir in Directory.GetDirectories(srcPath))
			CopyAndReplaceDirectory(dir, Path.Combine(dstPath, Path.GetFileName(dir)));
	}

	[PostProcessBuild]
	public static void OnPostprocessBuild(BuildTarget buildTarget, string path) {
	
		if (buildTarget == BuildTarget.iPhone) {
			string projPath = path + "/Unity-iPhone.xcodeproj/project.pbxproj";
			
			PBXProject proj = new PBXProject();
			proj.ReadFromString(File.ReadAllText(projPath));

			string target = proj.TargetGuidByName("Unity-iPhone");

			// Add user packages to project. Most other source or resource files and packages 
			// can be added the same way.
			CopyAndReplaceDirectory("NativeAssets/TestLib.bundle", Path.Combine(path, "Frameworks/TestLib.bundle"));
			proj.AddFileToBuild(target, proj.AddFile("Frameworks/TestLib.bundle", 
													 "Frameworks/TestLib.bundle", PBXSourceTree.Source));
			
			CopyAndReplaceDirectory("NativeAssets/TestLib.framework", Path.Combine(path, "Frameworks/TestLib.framework"));
			proj.AddFileToBuild(target, proj.AddFile("Frameworks/TestLib.framework", 
													 "Frameworks/TestLib.framework", PBXSourceTree.Source));
		
			// Add custom system frameworks. Duplicate frameworks are ignored.
			// needed by our native plugin in Assets/Plugins/iOS
			proj.AddFrameworkToProject(target, "AssetsLibrary.framework", false /*not weak*/);

			// Add our framework directory to the framework include path
			proj.SetBuildProperty(target, "FRAMEWORK_SEARCH_PATHS", "$(inherited)");
			proj.AddBuildProperty(target, "FRAMEWORK_SEARCH_PATHS", "$(PROJECT_DIR)/Frameworks");

			// Set a custom link flag
			proj.AddBuildProperty(target, "OTHER_LDFLAGS", "-ObjC");

			File.WriteAllText(projPath, proj.WriteToString());
		}
	}
}

