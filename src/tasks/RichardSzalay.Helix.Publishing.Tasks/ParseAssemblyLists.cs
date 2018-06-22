using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public class ParseAssemblyLists : Task
    {
        private readonly IFileSystem fileSystem;
        private readonly IAssemblyListParser assemblyListParser;

        [Required]
        public ITaskItem[] Files { get; set; }

        [Output]
        public ITaskItem[] Output { get; set; }

        public ParseAssemblyLists()
            : this(new FileSystem(), new AssemblyListParser())
        {
        }

        public ParseAssemblyLists(IFileSystem fileSystem, IAssemblyListParser assemblyListParser)
        {
            this.fileSystem = fileSystem;
            this.assemblyListParser = assemblyListParser;
        }

        public override bool Execute()
        {
            if (Files == null || Files.Length == 0)
            {
                Log.LogError("No files were supplied");
                return false;
            }

            try
            {
                Output = Files
                    .SelectMany(ParseAssemblyList)
                    .ToArray();

                return true;
            }
            catch (Exception ex)
            {
                Log.LogErrorFromException(ex);
                return false;
            }
        }

        private IEnumerable<ITaskItem> ParseAssemblyList(ITaskItem sourceItem)
        {
            var sourceItemFullPath = sourceItem.GetMetadata("FullPath");

            try
            {
                using (var stream = fileSystem.OpenRead(sourceItemFullPath))
                using (var reader = new StreamReader(stream))
                {
                    return assemblyListParser.Parse(reader)
                        .Select(entry => CreateAssemblyListEntryItem(entry, sourceItem))
                        .ToList();
                }
            }
            catch(Exception ex)
            {
                throw new Exception($"Exception parsing assembly list: {sourceItemFullPath}", ex);
            }
        }

        private ITaskItem CreateAssemblyListEntryItem(AssemblyListEntry entry, ITaskItem sourceItem)
        {
            return new TaskItem(entry.Assembly, new Dictionary<string, string>
            {
                ["FileVersion"] = entry.FileVersion,
                ["AssemblyVersion"] = entry.AssemblyVersion,
                ["Source"] = Path.GetFileName(sourceItem.GetMetadata("FullPath"))
            });
        }
    }
}
