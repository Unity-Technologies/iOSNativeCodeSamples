using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;

public class PostprocessBuild
{
    [PostProcessBuild]
    public static void OnPostprocessBuild(BuildTarget buildTarget, string path)
    {
        if (buildTarget == BuildTarget.iOS)
        {
            string projPath = path + "/Unity-iPhone.xcodeproj/project.pbxproj";

            PBXProject proj = new PBXProject();
            proj.ReadFromString(File.ReadAllText(projPath));

            string target = proj.GetUnityMainTargetGuid();
            string resSection = proj.GetResourcesBuildPhaseByTarget(target);

            proj.AddFileToBuildSection(target, resSection, proj.AddFile("Libraries/Soft.png","Libraries/Soft.png", PBXSourceTree.Source));
            proj.AddFileToBuildSection(target, resSection, proj.AddFile("Libraries/Test_Icon.png","Libraries/Test_Icon.png", PBXSourceTree.Source));
            proj.AddFileToBuildSection(target, resSection, proj.AddFile("Libraries/Test_UnityLogoLarge.png","Libraries/Test_UnityLogoLarge.png", PBXSourceTree.Source));

            File.WriteAllText(projPath, proj.WriteToString());
        }
    }
}
