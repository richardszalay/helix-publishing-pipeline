using Microsoft.Build.Framework;
using Xunit;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class ParseAssemblyListTests
    {
        private readonly FakeFileSystem fileSystem;
        private readonly FakeBuildEngine buildEngine;
        private readonly FilterBinaryUnchangedFiles sut;

        public ParseAssemblyListTests()
        {
            fileSystem = new FakeFileSystem();

            buildEngine = new FakeBuildEngine();

            sut = new FilterBinaryUnchangedFiles(fileSystem);
            sut.BuildEngine = buildEngine;
            sut.RelativePathMetadata = "RelativePath";
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
        public void MissingFiles_AreExcludedFromOutput()
        {
            sut.Files = new[]
            {
                new FakeTaskItem("file1.txt")
            };

            var result = sut.Execute();

            Assert.True(result);
            Assert.Empty(sut.Output);
        }

        [Fact]
        public void ModifiedFiles_AreExcludedFromOutput()
        {
            sut.Files = new[]
            {
                new FakeTaskItem("file1.txt")
                {
                    { "FullPath", @"source\file1.txt" },
                    { "RelativePath", "file1-1.txt" }
                }
            };

            sut.TargetDirectory = "target";

            fileSystem.AddFile(@"source\file1.txt", "aaa");
            fileSystem.AddFile(@"target\file1-1.txt", "bbb");

            var result = sut.Execute();

            Assert.True(result);
            Assert.Empty(sut.Output);
        }

        [Fact]
        public void FilesOfDifferentSizes_AreExcludedFromOutput()
        {
            sut.Files = new[]
            {
                new FakeTaskItem("file1.txt")
                {
                    { "FullPath", @"source\file1.txt" },
                    { "RelativePath", "file1-1.txt" }
                }
            };

            sut.TargetDirectory = "target";

            fileSystem.AddFile(@"source\file1.txt", "aaa");
            fileSystem.AddFile(@"target\file1-1.txt", "bbbbbb");

            var result = sut.Execute();

            Assert.True(result);
            Assert.Empty(sut.Output);
        }

        [Fact]
        public void IdenticalFiles_AreIncludedInOutput()
        {
            sut.Files = new[]
            {
                new FakeTaskItem("file1.txt")
                {
                    { "FullPath", @"source\file1.txt" },
                    { "RelativePath", "file1-1.txt" }
                }
            };

            sut.TargetDirectory = "target";

            fileSystem.AddFile(@"source\file1.txt", "aaa");
            fileSystem.AddFile(@"target\file1-1.txt", "aaa");

            var result = sut.Execute();

            Assert.True(result);
            Assert.Single(sut.Output, sut.Files[0]);
        }
    }
}
