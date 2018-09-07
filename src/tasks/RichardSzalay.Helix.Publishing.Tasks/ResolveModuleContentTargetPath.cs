using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public class ResolveModuleContentTargetPath : Task
    {
        [Required]
        public ITaskItem Module { get; set; }

        [Required]
        public ITaskItem[] Content { get; set; }

        [Required]
        public string TargetPathMetadataName { get; set; }

        [Required]
        public string ModuleMetadataPrefix { get; set; }

        [Output]
        public ITaskItem[] Output { get; set; }

        public override bool Execute()
        {
            var output = new List<ITaskItem>();

            foreach (var content in Content)
            {
                var resolvedTargetPath = ResolveTargetPath(content, Module);

                if (Path.IsPathRooted(resolvedTargetPath) || resolvedTargetPath.StartsWith(".."))
                {
                    var contentFullPath = content.GetMetadata("FullPath");
                    var targetPath = content.GetMetadata(TargetPathMetadataName);

                    if (string.IsNullOrEmpty(targetPath))
                    {
                        Log.LogError($"Could not resolve {TargetPathMetadataName} for {contentFullPath}");
                    }
                    else
                    {
                        Log.LogError($"Could not resolve {TargetPathMetadataName} '{targetPath}' to a relative path for {contentFullPath}");
                    }

                    return false;
                }
                // TODO: Write error if resolvedTargetPath is absolute or starts with ..

                var cloned = new TaskItem(content);

                cloned.SetMetadata(TargetPathMetadataName, resolvedTargetPath);

                output.Add(cloned);
            }

            Output = output.ToArray();

            return true;
        }

        private string ResolveTargetPath(ITaskItem content, ITaskItem module)
        {
            var targetPathTemplate = content.GetMetadata(TargetPathMetadataName);

            if (string.IsNullOrEmpty(targetPathTemplate))
            {
                return GetRelativePath(content, module);
            }

            return Regex.Replace(targetPathTemplate, @"\^\(([^)]+)\)", (match) =>
            {
                var key = match.Groups[1].Value;

                if (key.StartsWith($"{ModuleMetadataPrefix}."))
                {
                    var moduleKey = key.Substring(ModuleMetadataPrefix.Length + 1);

                    return module.GetMetadata(moduleKey);
                }

                if (content.MetadataNames.OfType<string>().Contains(key))
                {
                    return content.GetMetadata(key);
                }

                return content.GetMetadata(key);
            });
        }

        private static string GetRelativePath(ITaskItem content, ITaskItem relativeTo)
        {
            // TODO: Throw if result is absolute
            return MakeRelativePath(
                relativeTo.GetMetadata("FullPath"),
                content.GetMetadata("FullPath")                
            );
        }

        private static string MakeRelativePath(string fromPath, string toPath)
        {
            if (string.IsNullOrEmpty(fromPath)) throw new ArgumentNullException("fromPath");
            if (string.IsNullOrEmpty(toPath)) throw new ArgumentNullException("toPath");

            Uri fromUri = new Uri(fromPath);
            Uri toUri = new Uri(toPath);

            if (fromUri.Scheme != toUri.Scheme) { return toPath; } // path can't be made relative.

            Uri relativeUri = fromUri.MakeRelativeUri(toUri);
            string relativePath = Uri.UnescapeDataString(relativeUri.ToString());

            if (toUri.Scheme.Equals("file", StringComparison.InvariantCultureIgnoreCase))
            {
                relativePath = relativePath.Replace(Path.AltDirectorySeparatorChar, Path.DirectorySeparatorChar);
            }

            return relativePath;
        }
    }
}
