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
            string plistPath = path + "/Info.plist";

            PlistDocument doc = new PlistDocument();
            doc.ReadFromFile(plistPath);
            doc.root.SetString("NSPhotoLibraryUsageDescription", "TEST");
            doc.WriteToFile(plistPath);
        }
    }
}
