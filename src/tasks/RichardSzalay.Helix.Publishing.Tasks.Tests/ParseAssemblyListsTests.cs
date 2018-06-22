using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Build.Framework;
using Xunit;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class ParseAssemblyListsTests
    {
        private readonly FakeFileSystem fileSystem;
        private readonly FakeAssemblyParser assemblyListParser;
        private readonly FakeBuildEngine buildEngine;
        private readonly ParseAssemblyLists sut;

        public ParseAssemblyListsTests()
        {
            fileSystem = new FakeFileSystem();
            assemblyListParser = new FakeAssemblyParser();

            buildEngine = new FakeBuildEngine();

            sut = new ParseAssemblyLists(fileSystem, assemblyListParser);
            sut.BuildEngine = buildEngine;
        }

        [Fact]
        public void NoFiles_ReturnsFalse()
        {
            sut.Files = new ITaskItem[0];

            var result = sut.Execute();

            Assert.False(result);
            Assert.Single(buildEngine.LoggedErrorEvents);
        }

        [Fact]
        public void Files_AreParsedAndReturnedWithMetadata()
        {
            sut.Files = new[]
            {
                CreateFakeAssemblyList("file1.txt",
                    CreateEntry("Asm1", "1.0", "2.0"),
                    CreateEntry("Asm2", "2.0", "3.0")
                )
            };

            var result = sut.Execute();

            Assert.True(result);
            Assert.Equal(
                expected: new List<ITaskItem>
                {
                    CreateEntryItem("file1.txt", "Asm1", "1.0", "2.0"),
                    CreateEntryItem("file1.txt", "Asm2", "2.0", "3.0")
                },
                actual: sut.Output,
                comparer: new TaskItemComparer()
            );
        }

        [Fact]
        public void MultipleFiles_EachIncludeOriginalSource()
        {
            sut.Files = new[]
            {
                CreateFakeAssemblyList("file1.txt",
                    CreateEntry("Asm1", "1.0", "2.0"),
                    CreateEntry("Asm2", "2.0", "3.0")
                ),
                CreateFakeAssemblyList("file2.txt",
                    CreateEntry("Asm3", "3.0", "4.0"),
                    CreateEntry("Asm4", "4.0", "5.0")
                )
            };

            var result = sut.Execute();

            Assert.True(result);
            Assert.Equal(
                expected: new List<ITaskItem>
                {
                    CreateEntryItem("file1.txt", "Asm1", "1.0", "2.0"),
                    CreateEntryItem("file1.txt", "Asm2", "2.0", "3.0"),
                    CreateEntryItem("file2.txt", "Asm3", "3.0", "4.0"),
                    CreateEntryItem("file2.txt", "Asm4", "4.0", "5.0")
                },
                actual: sut.Output,
                comparer:  new TaskItemComparer()
            );
        }

        private ITaskItem CreateEntryItem(string source, string assembly, string fileVersion, string assemblyVersion)
        {
            return new FakeTaskItem(assembly)
            {
                { "Source", source },
                { "FileVersion", fileVersion },
                { "AssemblyVersion", assemblyVersion }
            };
        }

        private ITaskItem CreateFakeAssemblyList(string fullPath, params AssemblyListEntry[] entries)
        {
            fileSystem.AddFile(fullPath, fullPath);
            assemblyListParser.Files[fullPath] = entries.ToList();

            return new FakeTaskItem(fullPath)
            {
                {  "FullPath", fullPath }
            };
        }

        static AssemblyListEntry CreateEntry(string assembly, string fileVersion, string assemblyVersion)
        {
            return new AssemblyListEntry
            {
                Assembly = assembly,
                FileVersion = fileVersion,
                AssemblyVersion = assemblyVersion
            };
        }

        private class TaskItemComparer : IEqualityComparer<ITaskItem>
        {
            public bool Equals(ITaskItem x, ITaskItem y)
            {
                if (x.ItemSpec != y.ItemSpec)
                    return false;

                foreach(string metadataName in x.MetadataNames)
                {
                    if (x.GetMetadata(metadataName) != y.GetMetadata(metadataName))
                    {
                        return false;
                    }
                }

                return true;
            }

            public int GetHashCode(ITaskItem obj)
            {
                throw new NotImplementedException();
            }
        }
    }
}
